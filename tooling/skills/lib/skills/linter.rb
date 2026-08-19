# frozen_string_literal: true

module Skills
  class Linter
    def initialize(config:, catalog:, profiles:)
      @config = config
      @catalog = catalog
      @profiles = profiles
    end

    def call(strict: false)
      manifest_names, findings = manifest_for_lint
      findings.concat(@catalog.structural_findings)
      duplicate_names = manifest_names.tally.select { |_name, count| count > 1 }.keys.sort
      if duplicate_names.any?
        findings << Finding.new(:error, "global manifest contains duplicate skill names: #{duplicate_names.join(", ")}")
      end
      manifest_names.each do |name|
        findings << Finding.new(:error, "global manifest references missing skill #{name}") unless @catalog[name]
      end
      @catalog.skills.each_value { |skill| lint_skill(skill, manifest_names, findings) }
      lint_global_dependencies(manifest_names, findings)
      findings.concat(@profiles.findings(@catalog))
      findings.map! { |finding| Finding.new(:error, finding.message) } if strict
      Result.new(findings, nil)
    end

    private

    def manifest_for_lint
      findings = []
      findings << Finding.new(:error, "global manifest is missing: #{@config.global_manifest}") unless @config.global_manifest.file?
      [@config.manifest_skills, findings]
    rescue ArgumentError => error
      [[], [Finding.new(:error, error.message)]]
    end

    def lint_skill(skill, manifest_names, findings)
      metadata = skill.metadata
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

    def lint_global_dependencies(manifest_names, findings)
      global_set = manifest_names.to_set
      manifest_names.uniq.each do |name|
        skill = @catalog[name]
        next unless skill

        dependencies = skill.path.join("SKILL.md").read.scan(/`([a-z0-9][a-z0-9-]*)`/).flatten
                            .select { |reference| @catalog[reference] && reference != name && !global_set.include?(reference) }
                            .uniq.sort
        if dependencies.any?
          findings << Finding.new(:warning, "global dependency outside manifest: #{name} -> #{dependencies.join(", ")}")
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


    def reference_exists?(skill, reference)
      skill.path.join(reference).exist? || @config.root.join(reference).exist?
    end
  end
end
