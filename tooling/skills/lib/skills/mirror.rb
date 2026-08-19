# frozen_string_literal: true

module Skills
  Action = Data.define(:type, :name, :source, :target, :detail)

  class Mirror
    EXCLUDED = Set.new([".DS_Store", ".skillkit.json", ".skillfish.json", ".git"])

    def initialize(catalog:, config:)
      @catalog = catalog
      @config = config
    end

    def plan(names, targets: @config.targets)
      actions = []
      targets.each do |target|
        names.each do |name|
          skill = @catalog[name]
          next unless skill

          actions << copy_action(skill, target.path.join(name))
        end
        actions.concat(removal_actions(names, target))
      end
      actions
    end

    def apply(actions, backup_root: default_backup_root)
      stamp = Time.now.strftime("%Y%m%d-%H%M%S-%6N")
      actions.filter_map do |action|
        begin
          case action.type
          when :add, :update then atomic_copy(action.source, action.target)
          when :remove then backup(action.target, backup_root.join(stamp))
          end
          nil
        rescue StandardError => error
          Finding.new(:error, "#{action.type} #{action.target} failed: #{error.message}")
        end
      end
    end

    def default_backup_root
      state = ENV.fetch("XDG_STATE_HOME", File.join(Dir.home, ".local/state"))
      Pathname(state).join("skills-backups")
    end

    def fingerprint(directory)
      files(directory).sort.map do |path|
        relative = path.relative_path_from(directory).to_s
        [relative, Digest::SHA256.file(path).hexdigest]
      end
    end

    def atomic_copy(source, destination, rename: File.method(:rename))
      FileUtils.mkdir_p(destination.dirname)
      temporary = destination.dirname.join(".#{destination.basename}.skills-#{Process.pid}-#{rand(1_000_000)}")
      rollback = destination.dirname.join(".#{destination.basename}.skills-rollback-#{Process.pid}-#{rand(1_000_000)}")
      FileUtils.rm_rf(temporary)
      FileUtils.mkdir_p(temporary)
      files(source).each do |file|
        output = temporary.join(file.relative_path_from(source))
        FileUtils.mkdir_p(output.dirname)
        FileUtils.cp(file, output)
      end
      rename.call(destination, rollback) if destination.exist?
      rename.call(temporary, destination)
      FileUtils.rm_rf(rollback) if rollback.exist?
    rescue StandardError
      rename.call(rollback, destination) if defined?(rollback) && rollback&.exist? && !destination.exist?
      raise
    ensure
      FileUtils.rm_rf(temporary) if defined?(temporary) && temporary&.exist?
    end

    private

    def copy_action(skill, destination)
      return Action.new(:skip_link, skill.name, skill.path, destination, "target is a symlink") if destination.symlink?
      return Action.new(:add, skill.name, skill.path, destination, nil) unless destination.exist?

      type = fingerprint(skill.path) == fingerprint(destination) ? :unchanged : :update
      Action.new(type, skill.name, skill.path, destination, nil)
    end

    def removal_actions(names, target)
      return [] unless target.path.directory?

      target.path.children.select(&:directory?).sort.filter_map do |entry|
        name = entry.basename.to_s
        next if names.include?(name) || name == ".system"
        next Action.new(:skip_link, name, nil, entry, "target is a symlink") if entry.symlink?
        next Action.new(:skip_allowlist, name, nil, entry, "allowlisted") if allowed?(name)

        Action.new(:remove, name, nil, entry, nil)
      end
    end

    def allowed?(name)
      @config.allowlist.any? { |pattern| File.fnmatch?(pattern, name) }
    end

    def files(directory)
      Find.find(directory.to_s).filter_map do |entry|
        path = Pathname(entry)
        if path.directory? && path != directory && EXCLUDED.include?(path.basename.to_s)
          Find.prune
          next
        end
        next if path == directory || EXCLUDED.include?(path.basename.to_s) || !path.file?

        path
      end
    end

    def backup(path, directory)
      FileUtils.mkdir_p(directory)
      destination = collision_safe_destination(directory, path.basename.to_s)
      FileUtils.mv(path, destination)
    end

    def collision_safe_destination(directory, basename)
      destination = directory.join(basename)
      suffix = 2
      while destination.exist?
        destination = directory.join("#{basename}-#{suffix}")
        suffix += 1
      end
      destination
    end
  end
end
