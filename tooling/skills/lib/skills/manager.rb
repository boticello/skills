# frozen_string_literal: true

module Skills
  class Manager
    attr_reader :config, :catalog

    def initialize(root: Dir.pwd, home: Dir.home)
      @home = Pathname(home)
      @config = Config.load(root)
      @catalog = Catalog.new(config)
      @profiles = Profiles.new(config: config)
      @projects = Projects.new(config: config, catalog: catalog)
      @linter = Linter.new(config: config, catalog: catalog, profiles: @profiles)
      @doctor = Doctor.new(config: config, catalog: catalog, profiles: @profiles,
                           projects: @projects, linter: @linter, home: @home)
      @vendor = Vendor.new(config: config, catalog: catalog)
    end

    def resolved(project: nil)
      names = project ? config.project_resolution(project) : global_resolution.first
      names.select { |name| catalog[name] }
    end

    def deploy(project: nil, apply: false)
      project_error = validate_project(project)
      return Result.new([project_error], { kind: :deploy, actions: [], applied: false }) if project_error

      names, findings = resolution(project: project)
      return Result.new(findings, { kind: :deploy, names: names, actions: [], applied: false }) if names.empty?

      targets = project ? project_targets(project) : config.targets
      mirror = Mirror.new(catalog: catalog, config: config)
      actions = mirror.plan(names, targets: targets)
      findings.concat(plan_findings(actions))
      attempted = apply && findings.none? { |finding| finding.severity == :error }
      apply_findings = attempted ? mirror.apply(actions) : []
      findings.concat(apply_findings)
      Result.new(findings, {
        kind: :deploy,
        names: names,
        actions: actions,
        applied: attempted && apply_findings.empty?,
        partial: attempted && apply_findings.any?
      })
    end

    def list(project: nil)
      names, resolution_findings = resolution
      actions = names.empty? ? [] : Mirror.new(catalog: catalog, config: config).plan(names)
      projects, project_findings = @projects.memberships(project)
      suites = @profiles.memberships
      rows = catalog.names.map do |name|
        skill = catalog[name]
        {
          name: name,
          home: skill.home.to_s,
          vendor: skill.vendor,
          global: names.include?(name),
          projects: projects.fetch(name, []),
          suites: suites.fetch(name, []),
          drift: actions.select { |action| action.name == name }.map(&:type).uniq
        }
      end
      Result.new(resolution_findings + project_findings, { kind: :list, rows: rows })
    end

    def enable(name, project: nil, apply: false)
      mutate_manifest(name, project: project, apply: apply, enable: true)
    end

    def disable(name, project: nil, apply: false)
      mutate_manifest(name, project: project, apply: apply, enable: false)
    end

    def lint(strict: false)
      @linter.call(strict: strict)
    end

    def doctor(fix: false, apply: false, project: nil)
      @doctor.call(fix: fix, apply: apply, project: project)
    end

    def overlap(scope: "global", project: nil, suite: nil)
      source_findings = []
      names = case scope
              when "global" then resolved
              when "project"
                raise ArgumentError, "--project is required for --scope project" unless project

                error = validate_project(project)
                return Result.new([error], { kind: :overlap, pairs: [] }) if error

                resolved(project: project)
              when "suite"
                profile = @profiles.find(suite || raise(ArgumentError, "suite is required"))
                data = @profiles.read(profile)
                source_findings.concat(data.findings)
                data.skills
              else raise ArgumentError, "unknown overlap scope #{scope}"
              end
      result = Overlap.new(catalog: catalog).call(names: names, scope: scope)
      Result.new(source_findings + result.findings, result.payload)
    end

    def gather(name, from: nil, category: "personal", apply: false)
      validation = gather_path_findings(name, category)
      return Result.new(validation, { kind: :gather, applied: false }) if validation.any?

      source = gather_source(name, from)
      destination = config.root.join(category, name).cleanpath
      return Result.new([Finding.new(:error, "source skill not found: #{from || name}")], { kind: :gather, applied: false }) unless source
      if destination.exist?
        return Result.new([Finding.new(:error, "canonical destination exists: #{destination}")], { kind: :gather, applied: false })
      end

      Mirror.new(catalog: catalog, config: config).atomic_copy(source, destination) if apply
      Result.new([], { kind: :gather, source: source.to_s, destination: destination.to_s, applied: apply })
    rescue StandardError => error
      Result.new([Finding.new(:error, "gather failed: #{error.message}")], { kind: :gather, applied: false })
    end

    def fetch(repository, skill: nil, list: false, apply: false)
      @vendor.fetch(repository, skill: skill, list: list, apply: apply)
    end

    def fetch_all(apply: false)
      @vendor.fetch_all(apply: apply)
    end

    def update(name, ref: nil, apply: false, allow_missing: false)
      @vendor.update(name, ref: ref, apply: apply, allow_missing: allow_missing)
    end

    private

    def global_resolution
      return [catalog.names, [Finding.new(:error, "global manifest is missing; using the canonical catalogue as the safe fallback")]] unless config.global_manifest.file?

      names = config.manifest_skills
      return [[], [Finding.new(:error, "global manifest resolves to an empty skill set; refusing destructive mirror cleanup")]] if names.empty?

      [names, []]
    rescue ArgumentError => error
      [[], [Finding.new(:error, error.message)]]
    end

    def resolution(project: nil)
      requested, findings = if project
                              [config.project_resolution(project), []]
                            else
                              global_resolution
                            end
      findings.concat(catalog.structural_findings(names: requested))
      missing = requested.reject { |name| catalog[name] }
      label = project ? "project manifest" : "global manifest"
      findings.concat(missing.map { |name| Finding.new(:error, "#{label} references missing skill #{name}") })
      [requested - missing, findings]
    rescue ArgumentError => error
      [[], [Finding.new(:error, error.message)]]
    end

    def plan_findings(actions)
      actions.filter_map do |action|
        next unless action.type == :skip_link && action.source

        Finding.new(:error, "#{action.target}: resolved skill target is a symlink")
      end
    end

    def project_targets(project)
      [Target.new("agents", Pathname(project).join(".agents/skills"))]
    end

    def validate_project(project)
      return nil unless project

      path = Pathname(project).expand_path
      return nil if path.directory?

      Finding.new(:error, "project does not exist or is not a directory: #{path}")
    end

    def mutate_manifest(name, project:, apply:, enable:)
      return Result.new([Finding.new(:error, "unknown skill #{name}")], { kind: :manifest, applied: false }) unless catalog[name]
      if project
        project_error = validate_project(project)
        return Result.new([project_error], { kind: :manifest, applied: false }) if project_error

        return mutate_project_manifest(name, project, apply, enable)
      end

      names = enable ? config.manifest_skills | [name] : config.manifest_skills - [name]
      config.write_manifest(config.global_manifest, names) if apply
      Result.new([], { kind: :manifest, path: config.global_manifest.to_s, skills: names.sort, applied: apply })
    rescue ArgumentError => error
      Result.new([Finding.new(:error, error.message)], { kind: :manifest, applied: false })
    end

    def mutate_project_manifest(name, project, apply, enable)
      path = config.project_manifest(project)
      data = path.file? ? TomlRB.load_file(path) : {}
      add = Array(data.fetch("add", [])).map(&:to_s)
      exclude = Array(data.fetch("exclude", [])).map(&:to_s)
      global = config.manifest_skills.include?(name)
      if enable
        exclude -= [name]
        add |= [name] unless global
      else
        add -= [name]
        exclude |= [name] if global
      end
      config.write_project_manifest(path, add: add, exclude: exclude) if apply
      Result.new([], { kind: :manifest, path: path.to_s, add: add.sort, exclude: exclude.sort, applied: apply })
    rescue TomlRB::ParseError => error
      Result.new([Finding.new(:error, "invalid TOML in #{path}: #{error.message}")], { kind: :manifest, applied: false })
    end

    def gather_path_findings(name, category)
      findings = []
      findings << Finding.new(:error, "invalid skill name #{name.inspect}") unless name.match?(/\A[a-z0-9][a-z0-9-]*\z/)
      components = Pathname(category).each_filename.to_a
      valid_category = !Pathname(category).absolute? && components.any? && components.all? { |part| part.match?(/\A[a-z0-9][a-z0-9-]*\z/) }
      findings << Finding.new(:error, "invalid category #{category.inspect}") unless valid_category
      findings
    end

    def gather_source(name, from)
      candidates = if from
                     path = Pathname(from).expand_path
                     [path, path.join(name)]
                   else
                     config.targets.map { |target| target.path.join(name) } + [@home.join(".codex/skills", name)]
                   end
      candidates.find { |candidate| candidate.join("SKILL.md").file? }
    end
  end
end
