# frozen_string_literal: true

module Skills
  class Vendor
    SOURCES_HEADER = <<~HEADER.freeze
      # Provenance for vendored third-party skills (vendor/).
      #
      # Each entry records where a skill was fetched from and the exact commit it
      # was pinned to, so the skill is reproducible on a fresh machine even though
      # vendor/ itself is gitignored.
      #
      # Format:
      #   [skill-name]
      #   url = "https://github.com/owner/repo"
      #   commit = "<full sha>"
      #   path = "optional/path/to/skill"
      #
      # Preview and add entries with:
      #   tooling/skills/bin/skills fetch owner/repo
      #   tooling/skills/bin/skills fetch owner/repo --apply

    HEADER

    class CheckoutError < StandardError; end

    def initialize(config:, catalog:)
      @config = config
      @catalog = catalog
      @mirror = Mirror.new(catalog: catalog, config: config)
    end

    def fetch(repository, skill: nil, list: false, apply: false)
      url = normalize_repository(repository)
      with_checkout(url) do |checkout, commit|
        candidates = skill_candidates(checkout)
        if list
          return Result.new([], { source: url, candidates: candidates.map { |path| path.relative_path_from(checkout).to_s } })
        end

        chosen = choose_skill(candidates, skill, checkout: checkout)
        return Result.new([Finding.new(:error, "could not identify one skill in #{url}")], nil) unless chosen

        name = chosen == checkout ? repository_name(url) : chosen.basename.to_s
        destination = @config.root.join("vendor", name)
        return Result.new([Finding.new(:error, "vendor destination exists: #{destination}")], nil) if destination.exist?

        source_path = skill_path(chosen, checkout)
        payload = { source: url, commit: commit, destination: destination.to_s, applied: apply, action: "would fetch" }
        return Result.new([], payload) unless apply

        apply_vendor_change(name, chosen, destination, url: url, commit: commit, path: source_path)
        Result.new([], { source: url, destination: destination.to_s, applied: true })
      end
    rescue CheckoutError => error
      Result.new([Finding.new(:error, error.message)], nil)
    rescue StandardError => error
      Result.new([Finding.new(:error, "fetch failed for #{url}: #{error.message}")], nil)
    end

    def fetch_all(apply: false)
      sources = vendor_sources
      names = sources.keys.sort
      return Result.new([], { kind: :vendor, names: names, applied: false, action: "would rehydrate vendor" }) unless apply

      results = names.map do |name|
        source = sources.fetch(name)
        unless source.is_a?(Hash) && source["commit"].to_s.match?(/\A[0-9a-f]{40}\z/i)
          next Result.new([Finding.new(:error, "invalid SOURCES.toml entry for #{name}: verified commit is required")], nil)
        end

        update(name, ref: source.fetch("commit"), apply: true, allow_missing: true)
      end
      findings = results.flat_map(&:findings)
      Result.new(findings, {
        kind: :vendor,
        results: results.map(&:payload),
        applied: findings.empty?,
        partial: findings.any? && results.any? { |result| result.findings.empty? }
      })
    rescue ArgumentError => error
      Result.new([Finding.new(:error, error.message)], { kind: :vendor, applied: false })
    end

    def update(name, ref: nil, apply: false, allow_missing: false)
      source = vendor_sources[name]
      return Result.new([Finding.new(:error, "no SOURCES.toml entry for #{name}")], nil) unless source

      destination = @config.root.join("vendor", name)
      exists = destination.join("SKILL.md").file?
      return Result.new([Finding.new(:error, "vendor skill is missing: #{destination}")], nil) unless exists || allow_missing

      with_checkout(source.fetch("url"), ref: ref) do |checkout, commit|
        chosen = recorded_or_discovered_skill(source, checkout, name)
        return Result.new([Finding.new(:error, "recorded skill path is absent for #{name}")], nil) unless chosen&.join("SKILL.md").file?

        changed = !exists || @mirror.fingerprint(chosen) != @mirror.fingerprint(destination)
        source_path = skill_path(chosen, checkout)
        provenance_changed = commit != source["commit"] || source_path != source["path"]
        action = exists ? "would update" : "would rehydrate"
        payload = { name: name, source: source.fetch("url"), commit: commit, content_changed: changed,
                    provenance_changed: provenance_changed, applied: apply, action: action }
        return Result.new([], payload) unless apply
        return Result.new([], payload.merge(applied: true, action: "up to date")) unless changed || provenance_changed

        apply_vendor_change(name, chosen, destination, url: source.fetch("url"), commit: commit, path: source_path)
        Result.new([], { name: name, source: source.fetch("url"), commit: commit, applied: true })
      end
    rescue KeyError => error
      Result.new([Finding.new(:error, "invalid SOURCES.toml entry for #{name}: missing #{error.key}")], nil)
    rescue CheckoutError => error
      Result.new([Finding.new(:error, error.message)], nil)
    rescue ArgumentError => error
      Result.new([Finding.new(:error, error.message)], nil)
    rescue StandardError => error
      Result.new([Finding.new(:error, "update failed for #{name}: #{error.message}")], nil)
    end

    private

    def normalize_repository(repository)
      path = Pathname(repository)
      return path.expand_path.to_s if path.exist?

      repository.include?("://") ? repository : "https://github.com/#{repository}"
    end

    def vendor_sources
      path = @config.root.join("SOURCES.toml")
      return {} unless path.file?

      document = TomlRB.load_file(path)
      raise ArgumentError, "SOURCES.toml must contain tables" unless document.is_a?(Hash)

      document.transform_keys(&:to_s)
    rescue TomlRB::ParseError => error
      raise ArgumentError, "invalid TOML in #{path}: #{error.message}"
    end

    def with_checkout(url, ref: nil)
      temporary = Pathname(Dir.mktmpdir("skills-vendor"))
      checkout = temporary.join("repo")
      cloned = system("git", "clone", "--quiet", url, checkout.to_s, out: File::NULL, err: File::NULL)
      raise CheckoutError, "could not clone #{url}" unless cloned
      if ref && !system("git", "-C", checkout.to_s, "checkout", "--quiet", "--detach", ref, out: File::NULL, err: File::NULL)
        raise CheckoutError, "could not checkout #{ref}"
      end

      yield checkout, git_commit(checkout)
    ensure
      FileUtils.rm_rf(temporary) if defined?(temporary) && temporary
    end

    def git_commit(checkout)
      stdout, stderr, status = Open3.capture3("git", "-C", checkout.to_s, "rev-parse", "HEAD")
      raise CheckoutError, "could not resolve checkout commit: #{stderr.strip}" unless status.success?

      stdout.strip
    end

    def skill_candidates(checkout)
      checkout.glob("**/SKILL.md").reject { |path| path.to_s.include?("/node_modules/") }.map(&:dirname).sort
    end

    def choose_skill(candidates, name, checkout:)
      return candidates.find { |candidate| candidate.basename.to_s == name } if name
      return checkout if checkout.join("SKILL.md").file?

      candidates.one? ? candidates.first : nil
    end

    def recorded_or_discovered_skill(source, checkout, name)
      return checkout.join(source["path"]) if source["path"]
      return checkout if checkout.join("SKILL.md").file?

      candidates = skill_candidates(checkout)
      candidates.find { |candidate| candidate.basename.to_s == name } || (candidates.one? ? candidates.first : nil)
    end

    def repository_name(url)
      File.basename(url, ".git").sub(/-(?:claude-)?skill\z/, "")
    end

    def skill_path(chosen, checkout)
      chosen == checkout ? nil : chosen.relative_path_from(checkout).to_s
    end

    def apply_vendor_change(name, source, destination, url:, commit:, path:)
      rollback = destination.dirname.join(".#{destination.basename}.vendor-rollback-#{Process.pid}-#{rand(1_000_000)}")
      FileUtils.mkdir_p(destination.dirname)
      File.rename(destination, rollback) if destination.exist?
      begin
        @mirror.atomic_copy(source, destination)
        write_source(name, url: url, commit: commit, path: path)
        FileUtils.rm_rf(rollback)
      rescue StandardError
        FileUtils.rm_rf(destination)
        File.rename(rollback, destination) if rollback.exist?
        raise
      end
    end

    def write_source(name, url:, commit:, path:)
      source_path = @config.root.join("SOURCES.toml")
      original = source_path.file? ? source_path.read : ""
      document = original.empty? ? {} : TomlRB.parse(original)
      entry = { "url" => url, "commit" => commit }
      entry["path"] = path if path
      document[name] = entry
      atomic_write(source_path, "#{sources_header(original)}#{TomlRB.dump(document)}")
    end

    def sources_header(text)
      match = text.match(/\A((?:(?:[ \t]*#.*)?\n)+)(?=\s*\[)/)
      match ? match[1] : SOURCES_HEADER
    end

    def atomic_write(path, content)
      temporary = path.dirname.join(".#{path.basename}.skills-#{Process.pid}-#{rand(1_000_000)}")
      File.write(temporary, content)
      File.rename(temporary, path)
    ensure
      FileUtils.rm_f(temporary) if defined?(temporary) && temporary
    end
  end
end
