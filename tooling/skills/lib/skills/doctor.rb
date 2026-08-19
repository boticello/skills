# frozen_string_literal: true

module Skills
  class Doctor
    Snapshot = Data.define(:findings, :manifest_names, :codex, :legacy_paths, :dead_project_references)

    def initialize(config:, catalog:, profiles:, projects:, linter:, home:)
      @config = config
      @catalog = catalog
      @profiles = profiles
      @projects = projects
      @linter = linter
      @home = Pathname(home)
    end

    def call(fix: false, apply: false, project: nil)
      state = snapshot(project)
      payload = { kind: :doctor, fix_requested: fix, fixed: false }
      fix_failures = []

      if fix
        pruned, removed = state.codex.prune_text
        if pruned.nil?
          if removable_dead_entries?(state.codex)
            fix_failures << Finding.new(:error, "Codex config: validated prune was refused")
          end
        else
          payload[:planned_codex_paths] = removed
          if apply && removed.any?
            begin
              apply_codex_prune(pruned)
              payload[:fixed] = true
              payload[:pruned_codex_paths] = removed
            rescue StandardError => error
              fix_failures << Finding.new(:error, "Codex config prune failed: #{error.message}")
            end
          end
        end

        payload[:planned_legacy_paths] = state.legacy_paths.map(&:to_s) if state.legacy_paths.any?
        if apply && state.legacy_paths.any?
          actions = state.legacy_paths.map { |path| Action.new(:remove, path.basename.to_s, nil, path, nil) }
          legacy_failures = Mirror.new(catalog: @catalog, config: @config).apply(actions)
          fix_failures.concat(legacy_failures)
          if legacy_failures.empty?
            payload[:fixed] = true
            payload[:retired_legacy_paths] = state.legacy_paths.map(&:to_s)
          end
        end

        if state.dead_project_references.any?
          payload[:planned_project_references] = state.dead_project_references.map do |reference|
            { manifest: reference.manifest.to_s, field: reference.field, name: reference.name }
          end
          if apply
            begin
              pruned_references = @projects.prune_dead_references(project)
              payload[:fixed] = true
              payload[:pruned_project_references] = pruned_references.map do |reference|
                { manifest: reference.manifest.to_s, field: reference.field, name: reference.name }
              end
            rescue StandardError => error
              fix_failures << Finding.new(:error, "project manifest prune failed: #{error.message}")
            end
          end
        end
      end

      findings = if apply && payload[:fixed]
                   snapshot(project).findings + fix_failures
                 else
                   state.findings + fix_failures
                 end
      Result.new(findings, payload)
    end

    private
    def snapshot(project)
      findings = @linter.call.findings
      manifest_names = load_manifest_names
      findings.concat(target_health_findings(manifest_names)) if manifest_names
      findings.concat(@projects.findings(project))
      dead_project_references = @projects.dead_references(project)
      codex = CodexConfig.load(codex_config_path)
      findings.concat(codex_findings(codex, manifest_names))
      legacy_paths = legacy_managed_paths(manifest_names)
      findings.concat(legacy_paths.map do |path|
        Finding.new(:error, "legacy Codex target contains managed copy #{path}")
      end)
      Snapshot.new(findings, manifest_names, codex, legacy_paths, dead_project_references)
    end


    def load_manifest_names
      return nil unless @config.global_manifest.file?

      @config.manifest_skills
    rescue ArgumentError
      nil
    end

    def target_health_findings(names)
      Mirror.new(catalog: @catalog, config: @config).plan(names).filter_map do |action|
        case action.type
        when :add then Finding.new(:error, "#{action.target}: missing resolved skill")
        when :update then Finding.new(:error, "#{action.target}: content differs from canonical")
        when :remove then Finding.new(:warning, "#{action.target}: unmanaged target skill")
        when :skip_link
          Finding.new(:error, "#{action.target}: resolved skill target is a symlink") if action.source
        end
      end
    end

    def codex_findings(codex, manifest_names)
      findings = codex.findings.dup
      classes = codex.classify(manifest_names || [])
      classes[:dead].each do |entry|
        note = entry.simple? ? "" : " (left alone: entry has keys beyond path/enabled)"
        findings << Finding.new(:error, "Codex config: dead skill path #{entry.path}#{note} — prune with `skills doctor --fix --apply`")
      end
      return findings unless manifest_names

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

    def removable_dead_entries?(codex)
      codex.classify([])[:dead].any?(&:simple?)
    end

    def legacy_managed_paths(manifest_names)
      return [] unless manifest_names

      root = @home.join(".codex/skills")
      return [] unless root.directory?

      manifest_names.filter_map do |name|
        path = root.join(name)
        next unless path.directory? && !path.symlink?
        next if @config.allowlist.any? { |pattern| File.fnmatch?(pattern, name) }

        path
      end
    end

    def apply_codex_prune(pruned)
      backup = Mirror.new(catalog: @catalog, config: @config).default_backup_root.join(unique_stamp)
      FileUtils.mkdir_p(backup)
      FileUtils.cp(codex_config_path, backup.join("codex-config.toml"))
      atomic_write(codex_config_path, pruned)
    end

    def atomic_write(path, content)
      FileUtils.mkdir_p(path.dirname)
      temporary = path.dirname.join(".#{path.basename}.skills-#{Process.pid}-#{rand(1_000_000)}")
      File.write(temporary, content)
      File.rename(temporary, path)
    ensure
      FileUtils.rm_f(temporary) if defined?(temporary) && temporary
    end

    def unique_stamp
      Time.now.strftime("%Y%m%d-%H%M%S-%6N")
    end

    def codex_config_path
      @home.join(".codex/config.toml")
    end
  end
end
