# frozen_string_literal: true

module Skills
  Skill = Data.define(:name, :path, :home, :vendor, :metadata)

  class Catalog
    attr_reader :config, :duplicates, :invalid

    def initialize(config)
      @config = config
      @duplicates = Hash.new { |hash, key| hash[key] = [] }
      @invalid = []
    end

    def skills
      @skills ||= discover
    end

    def [](name)
      skills[name]
    end

    def names
      skills.keys.sort
    end

    def structural_findings(names: nil)
      skills
      selected = names&.to_set
      findings = duplicates.filter_map do |name, paths|
        next if selected && !selected.include?(name)

        Finding.new(:error, "duplicate skill #{name}: #{paths.join(", ")}")
      end
      findings.concat(skills.each_value.filter_map do |skill|
        next if selected && !selected.include?(skill.name)

        skill_identity_findings(skill)
      end.flatten)
      findings
    end


    private

    def discover
      found = {}
      discover_tree(config.root, vendor: false) { |skill| add(found, skill) }
      vendor = config.root.join("vendor")
      discover_tree(vendor, vendor: true) { |skill| add(found, skill) } if vendor.directory?
      found
    end

    def discover_tree(root, vendor:)
      Find.find(root.to_s) do |entry|
        path = Pathname(entry)
        if path.directory? && ignored?(path, root, vendor)
          Find.prune
          next
        end
        next unless path.basename.to_s == "SKILL.md" && path.file?

        yield build_skill(path.dirname, vendor)
      end
    end

    def ignored?(path, root, vendor)
      return false if path == root
      return false if vendor

      relative = path.relative_path_from(config.root).each_filename.first
      config.ignore.include?(relative)
    end

    def build_skill(path, vendor)
      metadata = YAML.safe_load(frontmatter(path.join("SKILL.md")), permitted_classes: [], aliases: false)
      metadata = {} unless metadata.is_a?(Hash)
      name = path.basename.to_s
      Skill.new(name, path, path.relative_path_from(config.root), vendor, metadata)
    rescue Psych::Exception
      Skill.new(path.basename.to_s, path, path.relative_path_from(config.root), vendor, {})
    end

    def add(found, skill)
      if found.key?(skill.name)
        duplicates[skill.name] << found[skill.name].path unless duplicates[skill.name].any?
        duplicates[skill.name] << skill.path
      else
        found[skill.name] = skill
      end
    end


    def skill_identity_findings(skill)
      text = skill.path.join("SKILL.md").read
      return [Finding.new(:error, "#{skill.path}: missing YAML frontmatter")] unless text.start_with?("---")

      match = text.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)
      return [Finding.new(:error, "#{skill.path}: unterminated YAML frontmatter")] unless match

      metadata = YAML.safe_load(match[1], permitted_classes: [], aliases: false)
      return [Finding.new(:error, "#{skill.path}: frontmatter must be a mapping")] unless metadata.is_a?(Hash)
      return [] if metadata["name"] == skill.name

      [Finding.new(:error, "#{skill.path}: frontmatter name #{metadata["name"].inspect} does not match directory #{skill.name.inspect}")]
    rescue Psych::Exception => error
      [Finding.new(:error, "#{skill.path}: invalid YAML frontmatter (#{error.message})")]
    end
    def frontmatter(path)
      match = path.read.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)
      return "{}" unless match

      match[1]
    end
  end
end
