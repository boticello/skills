# frozen_string_literal: true

module Skills
  DeadProjectReference = Data.define(:manifest, :field, :name)

  class Projects
    def initialize(config:, catalog:)
      @config = config
      @catalog = catalog
    end

    def manifest_paths(explicit_project = nil)
      manifests = ([@config.root] + @config.project_roots).uniq.flat_map do |root|
        next [] unless root.directory?

        direct = @config.project_manifest(root)
        root.glob("**/.agents/skills-manifest.toml") | (direct.file? ? [direct] : [])
      end
      manifests << @config.project_manifest(explicit_project) if explicit_project
      manifests.select(&:file?).uniq.sort
    end

    def memberships(explicit_project = nil)
      memberships = Hash.new { |hash, key| hash[key] = [] }
      findings = []
      manifest_paths(explicit_project).each do |manifest|
        project = manifest.dirname.parent
        begin
          @config.project_resolution(project).each { |name| memberships[name] << project.to_s }
        rescue ArgumentError => error
          findings << Finding.new(:error, "#{manifest}: #{error.message}")
        end
      end
      memberships.each_value(&:sort!)
      [memberships, findings]
    end

    def findings(explicit_project = nil)
      dead_references(explicit_project).map do |reference|
        Finding.new(:error, "#{reference.manifest}: project manifest references missing skill #{reference.name}")
      end + parse_findings(explicit_project)
    end

    def dead_references(explicit_project = nil)
      manifest_paths(explicit_project).flat_map do |manifest|
        data = TomlRB.load_file(manifest)
        %w[add exclude].flat_map do |field|
          Array(data.fetch(field, [])).map(&:to_s).reject { |name| @catalog[name] }.map do |name|
            DeadProjectReference.new(manifest, field, name)
          end
        end
      rescue TomlRB::ParseError
        []
      end
    end

    def prune_dead_references(explicit_project = nil)
      removed = dead_references(explicit_project)
      removed.group_by(&:manifest).each do |manifest, references|
        data = TomlRB.load_file(manifest)
        names = references.map(&:name).to_set
        add = Array(data.fetch("add", [])).map(&:to_s) - names.to_a
        exclude = Array(data.fetch("exclude", [])).map(&:to_s) - names.to_a
        @config.write_project_manifest(manifest, add: add, exclude: exclude)
      end
      removed
    end

    private

    def parse_findings(explicit_project)
      manifest_paths(explicit_project).filter_map do |manifest|
        TomlRB.load_file(manifest)
        nil
      rescue TomlRB::ParseError => error
        Finding.new(:error, "invalid TOML in #{manifest}: #{error.message}")
      end
    end
  end
end
