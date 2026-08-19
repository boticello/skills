# frozen_string_literal: true

module Skills
  Finding = Data.define(:severity, :message)
  Result = Data.define(:findings, :payload) do
    def exit_code
      findings.any? { |finding| finding.severity == :error } ? 1 : 0
    end
  end

  class Manager
    attr_reader :config, :catalog

    def initialize(root: Dir.pwd, home: Dir.home)
      @home = Pathname(home)
      @config = Config.load(root)
      @catalog = Catalog.new(config)
    end

    def resolved(project: nil)
      names = project ? config.project_resolution(project) : config.manifest_skills
      names.select { |name| catalog[name] }
    end

    def deploy(project: nil, apply: false)
      names, findings = resolution(project: project)
      targets = project ? project_targets(project) : config.targets
      actions = Mirror.new(catalog: catalog, config: config).plan(names, targets: targets)
      Mirror.new(catalog: catalog, config: config).apply(actions) if apply
      Result.new(findings, { names: names, actions: actions, applied: apply })
    end

    def list(project: nil)
      actions = Mirror.new(catalog: catalog, config: config).plan(resolved)
      projects, project_findings = project_memberships(project)
      suites = suite_memberships
      Result.new(project_findings, catalog.names.map do |name|
        skill = catalog[name]
        drift = actions.select { |action| action.name == name }.map(&:type).uniq
        {
          name: name,
          home: skill.home.to_s,
          vendor: skill.vendor,
          global: config.manifest_skills.include?(name),
          projects: projects.fetch(name, []),
          suites: suites.fetch(name, []),
          drift: drift
        }
      end)
    end

    def enable(name, project: nil, apply: false)
      mutate_manifest(name, project: project, apply: apply, enable: true)
    end

    def disable(name, project: nil, apply: false)
      mutate_manifest(name, project: project, apply: apply, enable: false)
    end

    def lint(strict: false)
      manifest_names, manifest_findings = manifest_for_lint
      findings = manifest_findings
      catalog.duplicates.each { |name, paths| findings << Finding.new(:error, "duplicate skill #{name}: #{paths.join(", ")}") }
      duplicate_manifest_names = manifest_names.tally.select { |_name, count| count > 1 }.keys.sort
      findings << Finding.new(:error, "global manifest contains duplicate skill names: #{duplicate_manifest_names.join(", ")}") if duplicate_manifest_names.any?
      manifest_names.each { |name| findings << Finding.new(:error, "global manifest references missing skill #{name}") unless catalog[name] }
      catalog.skills.each_value do |skill|
        metadata, structural_findings = skill_metadata(skill)
        structural_findings.each do |finding|
          if finding.message.include?("frontmatter name") && !manifest_names.include?(skill.name)
            findings << Finding.new(:warning, "non-global metadata mismatch: #{finding.message}")
          else
            findings << finding
          end
        end
        findings << Finding.new(:warning, "#{skill.path}: description is missing") if metadata["description"].to_s.strip.empty?
        findings << Finding.new(:warning, "#{skill.path}: role/workflow-shaped name") if skill.name.match?(/(?:lead|supervisor|reviewer|workflow)/)
        findings << Finding.new(:warning, "#{skill.path}: over 200 lines") if skill.path.join("SKILL.md").readlines.length > 200
        if manifest_names.include?(skill.name) && !metadata.key?("triggers")
          findings << Finding.new(:warning, "#{skill.path}: global skill has no explicit triggers")
        end
        local_references(skill).each do |reference|
          findings << Finding.new(:error, "#{skill.path}: missing relative reference #{reference}") unless reference_exists?(skill, reference)
        end
        if skill.path.join("SKILL.md").read.include?("/Users/bear/Me/00-system/agents/skills")
          findings << Finding.new(:warning, "#{skill.path}: obsolete absolute skill path")
        end
      end
      global_set = manifest_names.to_set
      manifest_names.uniq.each do |name|
        skill = catalog[name]
        next unless skill

        dependencies = skill.path.join("SKILL.md").read.scan(/`([a-z0-9][a-z0-9-]*)`/).flatten
                            .select { |reference| catalog[reference] && reference != name && !global_set.include?(reference) }
                            .uniq.sort
        findings << Finding.new(:warning, "global dependency outside manifest: #{name} -> #{dependencies.join(", ")}") if dependencies.any?
      end
      agent_profiles.each do |profile|
        skills_for_profile(profile).each do |name|
          findings << Finding.new(:error, "#{profile}: profile references missing skill #{name}") unless catalog[name]
        end
      end
      findings.map! { |finding| Finding.new(:error, finding.message) } if strict
      Result.new(findings, nil)
    end

    def doctor(fix: false, apply: false, project: nil)
      findings = doctor_findings(project: project)
      pruned = apply_codex_prune if fix && apply
      findings = doctor_findings(project: project) if pruned&.any?
      payload = { fix_requested: fix, fixed: !pruned.nil? }
      payload[:pruned_codex_paths] = pruned unless pruned.nil?
      Result.new(findings, payload)
    end

    def overlap(scope: "global", project: nil, suite: nil)
      names = case scope
              when "global" then resolved
              when "project" then resolved(project: project || raise(ArgumentError, "--project is required"))
              when "suite" then skills_for_profile(profile_for(suite || raise(ArgumentError, "suite is required")))
              else raise ArgumentError, "unknown overlap scope #{scope}"
              end
      missing = names.reject { |name| catalog[name] }
      valid = names - missing
      pairs = valid.combination(2).filter_map do |left, right|
        shared = tokens(catalog[left]) & tokens(catalog[right])
        next if shared.empty?
        union = tokens(catalog[left]) | tokens(catalog[right])
        score = shared.length.to_f / union.length
        { left: left, right: right, score: score, shared: shared.sort } if score >= 0.25
      end
      findings = missing.map { |name| Finding.new(:error, "#{scope} scope references missing skill #{name}") }
      findings.concat(pairs.map { |pair| Finding.new(:warning, "#{pair[:left]} overlaps #{pair[:right]}: #{pair[:shared].join(", ")}") })
      Result.new(findings, pairs)
    end

    def gather(name, from:, category: "personal", apply: false)
      source = Pathname(from)
      destination = config.root.join(category, name)
      return Result.new([Finding.new(:error, "source skill not found: #{source}")], nil) unless source.join("SKILL.md").file?
      return Result.new([Finding.new(:error, "canonical destination exists: #{destination}")], nil) if destination.exist?
      Mirror.new(catalog: catalog, config: config).send(:atomic_copy, source, destination) if apply
      Result.new([], { source: source.to_s, destination: destination.to_s, applied: apply })
    end

    def fetch(repository, skill: nil, list: false, apply: false)
      url = Pathname(repository).exist? ? Pathname(repository).expand_path.to_s : (repository.include?("://") ? repository : "https://github.com/#{repository}")
      with_checkout(url) do |checkout, commit|
        candidates = skill_candidates(checkout)
        return Result.new([], { source: url, candidates: candidates.map { |path| path.relative_path_from(checkout).to_s } }) if list
        chosen = choose_skill(candidates, skill)
        return Result.new([Finding.new(:error, "could not identify one skill in #{url}")], nil) unless chosen
        name = chosen == checkout ? repository_name(url) : chosen.basename.to_s
        destination = config.root.join("vendor", name)
        return Result.new([Finding.new(:error, "vendor destination exists: #{destination}")], nil) if destination.exist?
        payload = { source: url, commit: commit, destination: destination.to_s, applied: apply, action: "would fetch" }
        return Result.new([], payload) unless apply

        Mirror.new(catalog: catalog, config: config).send(:atomic_copy, chosen, destination)
        write_source(name, url: url, commit: commit, path: skill_path(chosen, checkout))
        Result.new([], { source: url, destination: destination.to_s, applied: true })
      end
    end

    def fetch_all(apply: false)
      sources = vendor_sources
      return Result.new([Finding.new(:error, sources.fetch("__error__").fetch("error"))], nil) if sources.key?("__error__")

      names = sources.keys.sort
      return Result.new([], { names: names, applied: false, action: "would rehydrate vendor" }) unless apply

      results = names.map { |name| update(name, apply: true, allow_missing: true) }
      Result.new(results.flat_map(&:findings), { results: results.map(&:payload), applied: true })
    end

    def update(name, ref: nil, apply: false, allow_missing: false)
      sources = vendor_sources
      return Result.new([Finding.new(:error, sources.fetch("__error__").fetch("error"))], nil) if sources.key?("__error__")
      source = sources[name]
      return Result.new([Finding.new(:error, "no SOURCES.toml entry for #{name}")], nil) unless source
      destination = config.root.join("vendor", name)
      exists = destination.join("SKILL.md").file?
      return Result.new([Finding.new(:error, "vendor skill is missing: #{destination}")], nil) unless exists || allow_missing

      with_checkout(source.fetch("url"), ref: ref) do |checkout, commit|
        chosen = source["path"] ? checkout.join(source["path"]) : choose_skill(skill_candidates(checkout), name)
        return Result.new([Finding.new(:error, "recorded skill path is absent for #{name}")], nil) unless chosen&.join("SKILL.md").file?
        changed = !exists || Mirror.new(catalog: catalog, config: config).send(:fingerprint, chosen) != Mirror.new(catalog: catalog, config: config).send(:fingerprint, destination)
        provenance_changed = commit != source["commit"] || skill_path(chosen, checkout) != source["path"]
        payload = { name: name, source: source.fetch("url"), commit: commit, content_changed: changed, provenance_changed: provenance_changed, applied: apply, action: exists ? "would update" : "would rehydrate" }
        return Result.new([], payload) unless apply

        Mirror.new(catalog: catalog, config: config).send(:atomic_copy, chosen, destination)
        write_source(name, url: source.fetch("url"), commit: commit, path: skill_path(chosen, checkout))
        Result.new([], { name: name, source: source.fetch("url"), commit: commit, applied: true })
      end
    end

    private

    def doctor_findings(project: nil)
      lint.findings + target_health_findings + project_manifest_findings(project) + codex_config_findings
    end

    def resolution(project: nil)
      requested = project ? config.project_resolution(project) : config.manifest_skills
      missing = requested.reject { |name| catalog[name] }
      [requested - missing, missing.map { |name| Finding.new(:error, "#{project ? "project manifest" : "global manifest"} references missing skill #{name}") }]
    end

    def manifest_for_lint
      [config.manifest_skills, []]
    rescue ArgumentError => error
      [[], [Finding.new(:error, error.message)]]
    end

    def project_targets(project)
      project = Pathname(project)
      [Config::Target.new("agents", project.join(".agents/skills"))]
    end

    def project_memberships(explicit_project)
      memberships = Hash.new { |hash, key| hash[key] = [] }
      findings = []
      project_manifest_paths(explicit_project).each do |manifest|
        project = manifest.dirname.parent
        begin
          config.project_resolution(project).each { |name| memberships[name] << project.to_s }
        rescue ArgumentError => error
          findings << Finding.new(:error, "#{manifest}: #{error.message}")
        end
      end
      memberships.each_value(&:sort!)
      [memberships, findings]
    end

    def project_manifest_paths(explicit_project = nil)
      manifests = ([config.root] + config.project_roots).uniq.flat_map do |root|
        next [] unless root.directory?

        direct = config.project_manifest(root)
        root.glob("**/.agents/skills-manifest.toml") | (direct.file? ? [direct] : [])
      end
      manifests << config.project_manifest(explicit_project) if explicit_project
      manifests.select(&:file?).uniq.sort
    end

    def project_manifest_findings(explicit_project = nil)
      project_manifest_paths(explicit_project).flat_map do |manifest|
        data = TomlRB.load_file(manifest)
        references = Array(data.fetch("add", [])) | Array(data.fetch("exclude", []))
        references.map(&:to_s).reject { |name| catalog[name] }.map do |name|
          Finding.new(:error, "#{manifest}: project manifest references missing skill #{name}")
        end
      rescue TomlRB::ParseError => error
        [Finding.new(:error, "invalid TOML in #{manifest}: #{error.message}")]
      end
    end

    def suite_memberships
      memberships = Hash.new { |hash, key| hash[key] = [] }
      agent_profiles.sort.each do |profile|
        skills_for_profile(profile).each { |name| memberships[name] << profile.basename(".*").to_s }
      end
      memberships.each_value(&:sort!)
      memberships
    end

    def mutate_manifest(name, project:, apply:, enable:)
      return Result.new([Finding.new(:error, "unknown skill #{name}")], nil) unless catalog[name]
      return mutate_project_manifest(name, project, apply, enable) if project

      names = enable ? config.manifest_skills | [name] : config.manifest_skills - [name]
      config.write_manifest(config.global_manifest, names) if apply
      Result.new([], { path: config.global_manifest.to_s, skills: names.sort, applied: apply })
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
      Result.new([], { path: path.to_s, add: add.sort, exclude: exclude.sort, applied: apply })
    end

    def agent_profiles
      root = config.root.parent.join("agents")
      root.directory? ? root.glob("**/*.{md,yaml,yml}") : []
    end

    def profile_for(name)
      agent_profiles.find { |profile| profile.basename(".*").to_s == name } || raise(ArgumentError, "unknown suite #{name}")
    end

    def skills_for_profile(profile)
      text = profile.read
      frontmatter = text.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)&.[](1)
      return [] unless frontmatter

      data = YAML.safe_load(frontmatter, permitted_classes: [], aliases: false) || {}
      Array(data["skills"])
    rescue Psych::SyntaxError
      []
    end

    def codex_config_findings
      codex = CodexConfig.load(codex_config_path)
      findings = codex.findings.dup
      classes = codex.classify(config.manifest_skills)
      classes[:dead].each do |entry|
        note = entry.simple? ? "" : " (left alone: entry has keys beyond path/enabled)"
        findings << Finding.new(:error, "Codex config: dead skill path #{entry.path}#{note} — prune with `skills doctor --fix --apply`")
      end
      classes[:conflict].each do |entry|
        findings << Finding.new(:warning, "Codex config: #{entry.name} is in the global manifest but disabled in Codex — re-enable it in Codex, or run `skills disable #{entry.name} --global --apply`")
      end
      classes[:stray].each do |entry|
        findings << Finding.new(:warning, "Codex config: #{entry.name} is disabled in Codex but not in the global manifest (harmless; reported for the record)")
      end
      classes[:enabled].each do |entry|
        findings << Finding.new(:warning, "Codex config: #{entry.name} has an explicit enable entry")
      end
      findings
    end

    def apply_codex_prune
      codex = CodexConfig.load(codex_config_path)
      pruned, removed = codex.prune_text
      return nil if pruned.nil? || removed.empty?

      backup = Mirror.new(catalog: catalog, config: config).default_backup_root.join(Time.now.strftime("%Y%m%d-%H%M%S"))
      FileUtils.mkdir_p(backup)
      FileUtils.cp(codex_config_path, backup.join("codex-config.toml"))
      temporary = codex_config_path.dirname.join(".codex-config.skills-#{Process.pid}")
      File.write(temporary, pruned)
      File.rename(temporary, codex_config_path)
      removed
    end

    def codex_config_path
      @home.join(".codex/config.toml")
    end

    def target_health_findings
      Mirror.new(catalog: catalog, config: config).plan(resolved).filter_map do |action|
        case action.type
        when :add then Finding.new(:error, "#{action.target}: missing resolved skill")
        when :update then Finding.new(:error, "#{action.target}: content differs from canonical")
        when :remove then Finding.new(:warning, "#{action.target}: unmanaged target skill")
        end
      end
    end

    def local_references(skill)
      text = skill.path.join("SKILL.md").read
      markdown = text.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten
      raw = text.scan(/(?<![A-Za-z0-9_\.\/-])((?:references|scripts|docs|assets|templates|prompts)\/[A-Za-z0-9_\.\/-]+)/).flatten
      (markdown | raw).filter_map do |reference|
        reference = reference.split("#", 2).first
        next if reference.empty? || reference.start_with?("#", "http://", "https://", "mailto:", "/", "~", "$")
        next if ["...", "<", ">", "[[", "x.md", "foo.md"].any? { |token| reference.include?(token) }
        next if raw.include?(reference) && !markdown.include?(reference) && File.extname(reference).empty? && !reference.start_with?("../") && !reference.end_with?("/")
        next if markdown.include?(reference) && File.extname(reference).empty? && !reference.include?("/") && !reference.start_with?("./", "../")
        next if reference.start_with?("tools/") && File.extname(reference).empty?

        reference
      end.uniq
    end

    def skill_metadata(skill)
      text = skill.path.join("SKILL.md").read
      return [{}, [Finding.new(:error, "#{skill.path}: missing YAML frontmatter")]] unless text.start_with?("---")

      match = text.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)
      return [{}, [Finding.new(:error, "#{skill.path}: unterminated YAML frontmatter")]] unless match

      metadata = YAML.safe_load(match[1], permitted_classes: [], aliases: false) || {}
      declared_name = metadata["name"]
      findings = []
      findings << Finding.new(:error, "#{skill.path}: frontmatter name #{declared_name.inspect} does not match directory #{skill.name.inspect}") if declared_name != skill.name
      [metadata, findings]
    rescue Psych::SyntaxError => error
      [{}, [Finding.new(:error, "#{skill.path}: invalid YAML frontmatter (#{error.message})")]]
    end

    def reference_exists?(skill, reference)
      skill.path.join(reference).exist? || config.root.join(reference).exist?
    end

    def vendor_sources
      path = config.root.join("SOURCES.toml")
      return {} unless path.file?

      TomlRB.load_file(path).transform_keys(&:to_s)
    rescue TomlRB::ParseError => error
      { "__error__" => { "error" => error.message } }
    end

    def with_checkout(url, ref: nil)
      temporary = Pathname(Dir.mktmpdir("skills-vendor"))
      checkout = temporary.join("repo")
      success = system("git", "clone", "--quiet", url, checkout.to_s, out: File::NULL, err: File::NULL)
      return Result.new([Finding.new(:error, "could not clone #{url}")], nil) unless success
      return Result.new([Finding.new(:error, "could not checkout #{ref}")], nil) if ref && !system("git", "-C", checkout.to_s, "checkout", "--quiet", "--detach", ref, out: File::NULL, err: File::NULL)

      yield checkout, `git -C #{Shellwords.escape(checkout.to_s)} rev-parse HEAD`.strip
    ensure
      FileUtils.rm_rf(temporary) if defined?(temporary) && temporary
    end

    def skill_candidates(checkout)
      checkout.glob("**/SKILL.md").reject { |path| path.to_s.include?("/node_modules/") }.map(&:dirname).sort
    end

    def choose_skill(candidates, name)
      return candidates.find { |candidate| candidate.basename.to_s == name } if name
      candidates.one? ? candidates.first : nil
    end

    def repository_name(url)
      File.basename(url, ".git").sub(/-(?:claude-)?skill\z/, "")
    end

    def skill_path(chosen, checkout)
      chosen == checkout ? nil : chosen.relative_path_from(checkout).to_s
    end

    def write_source(name, url:, commit:, path:)
      source_path = config.root.join("SOURCES.toml")
      body = ["[#{name}]", "url = #{url.inspect}", "commit = #{commit.inspect}"]
      body << "path = #{path.inspect}" if path
      section = "#{body.join("\n")}\n"
      text = source_path.file? ? source_path.read : ""
      pattern = /^\[#{Regexp.escape(name)}\]\n.*?(?=^\[|\z)/m
      source_path.write(pattern.match?(text) ? text.sub(pattern, section) : "#{text.rstrip}\n\n#{section}")
    end

    def tokens(skill)
      text = [skill.metadata["description"], *Array(skill.metadata["triggers"])].join(" ").downcase
      Set.new(text.scan(/[a-z][a-z0-9-]{2,}/))
    end
  end
end
