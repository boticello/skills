# frozen_string_literal: true

module Skills
  ProfileData = Data.define(:skills, :findings)

  class Profiles
    def initialize(config:)
      @root = config.root.parent.join("agents/agents")
    end

    def files
      @root.directory? ? @root.glob("**/*.{md,yaml,yml}").sort : []
    end

    def find(name)
      matches = files.select { |profile| profile.basename(".*").to_s == name }
      raise ArgumentError, "unknown suite #{name}" if matches.empty?
      raise ArgumentError, "ambiguous suite #{name}: #{matches.join(", ")}" if matches.length > 1

      matches.first
    end

    def read(profile)
      text = profile.read
      frontmatter = text.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)&.[](1)
      return ProfileData.new([], [Finding.new(:error, "#{profile}: missing YAML frontmatter")]) unless frontmatter

      data = YAML.safe_load(frontmatter, permitted_classes: [], aliases: false)
      return ProfileData.new([], [Finding.new(:error, "#{profile}: frontmatter must be a mapping")]) unless data.is_a?(Hash)

      skills = data.fetch("skills", [])
      return ProfileData.new([], [Finding.new(:error, "#{profile}: skills must be an array")]) unless skills.is_a?(Array)

      ProfileData.new(skills.map(&:to_s), [])
    rescue Psych::Exception => error
      ProfileData.new([], [Finding.new(:error, "#{profile}: invalid YAML frontmatter (#{error.message})")])
    end

    def memberships
      memberships = Hash.new { |hash, key| hash[key] = [] }
      files.each do |profile|
        read(profile).skills.each { |name| memberships[name] << profile.basename(".*").to_s }
      end
      memberships.each_value(&:sort!)
      memberships
    end

    def findings(catalog)
      files.flat_map do |profile|
        data = read(profile)
        data.findings + data.skills.reject { |name| catalog[name] }.map do |name|
          Finding.new(:error, "#{profile}: profile references missing skill #{name}")
        end
      end
    end
  end
end
