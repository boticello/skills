# frozen_string_literal: true

module Skills
  # Codex's ~/.codex/config.toml carries [[skills.config]] entries: per-path
  # disable switches, path-keyed and owned by Codex. This class reads them,
  # classifies them against the global manifest, and prunes dead ones.
  #
  # Classification (D5):
  #   dead      — path no longer exists; rot. Codex ignores these. Prunable.
  #   conflict  — live path, disabled, and the skill IS in the global
  #               manifest. Two sources of truth disagree; reported, never
  #               resolved here (the disable is Codex-local intent).
  #   stray     — live path, disabled, skill not in the manifest. Reported.
  #   enabled   — live path, enabled. Reported when it appears.
  #
  # Writing rules: only dead entries whose keys are exactly {path, enabled}
  # are ever removed (unknown keys → untouched, reported as such). Removal is
  # line-surgical so surviving text keeps Codex's own formatting, and it is
  # validated by re-parsing: the pruned document must deep-equal the original
  # minus exactly the removed entries, or the write is refused. A timestamped
  # backup is taken first, matching the tool's backups-not-deletions rule.
  class CodexConfig
    SIMPLE_KEYS = Set.new(%w[path enabled]).freeze

    Entry = Data.define(:index, :path, :enabled, :name, :keys) do
      def simple?
        keys == SIMPLE_KEYS
      end
    end

    attr_reader :findings, :entries

    def self.load(path)
      new(path).tap(&:load)
    end

    def initialize(path)
      @path = Pathname(path)
      @findings = []
      @entries = []
      @text = nil
      @document = nil
    end

    def load
      return unless @path.file?

      @text = @path.read
      @document = TomlRB.parse(@text)
      raw = Array(@document.dig("skills", "config"))
      @entries = raw.each_with_index.map { |entry, index| build_entry(entry, index) }
    rescue TomlRB::ParseError => error
      @findings << Finding.new(:error, "Codex config is unparsable; refusing to touch it: #{error.message}")
      @entries = []
    end

    def classify(manifest_skills)
      dead = []
      conflict = []
      stray = []
      enabled = []
      entries.each do |entry|
        next unless entry.path

        if !File.exist?(entry.path)
          dead << entry
        elsif entry.enabled == false
          (manifest_skills.include?(entry.name) ? conflict : stray) << entry
        else
          enabled << entry
        end
      end
      { dead: dead, conflict: conflict, stray: stray, enabled: enabled }
    end

    # Returns [pruned_text, removed_paths]; [nil, []] when validation refuses.
    def prune_text
      return [nil, []] if @text.nil? || @document.nil?

      candidates = classify([])[:dead].select(&:simple?)
      return [@text, []] if candidates.empty?

      removed_paths = []
      removed_indices = []
      drop_ranges = []
      block_ranges.each_with_index do |(start, stop, body), index|
        entry = parse_block(body)
        next unless entry

        next unless candidates.any? { |candidate| candidate.index == index }

        drop_ranges << removable_lines(start, body)
        removed_paths << entry["path"]
        removed_indices << index
      end
      pruned = @text.lines.each_with_index
                    .reject { |_line, index| drop_ranges.any? { |start, stop| index >= start && index < stop } }
                    .map(&:first).join
      valid_prune?(pruned, removed_indices) ? [pruned, removed_paths] : [nil, []]
    end

    private

    def build_entry(entry, index)
      path = entry["path"]
      Entry.new(
        index: index,
        path: path,
        enabled: entry["enabled"],
        name: path ? File.basename(File.dirname(path)) : nil,
        keys: Set.new(entry.keys.map(&:to_s))
      )
    end

    # [[skills.config]] block line ranges: [start, stop) plus the block body,
    # where stop is the next table header or end of file. Consecutive blocks
    # close each other.
    def block_ranges
      ranges = []
      start = nil
      lines = @text.lines
      lines.each_with_index do |line, index|
        header = line.strip
        next unless header.start_with?("[")
        if start
          ranges << [start, index, lines[start...index].join]
          start = nil
        end
        start = index if header.start_with?("[[skills.config]]")
      end
      ranges << [start, lines.length, lines[start..].join] if start
      ranges
    end

    def parse_block(body)
      TomlRB.parse(body).dig("skills", "config")&.first
    rescue TomlRB::ParseError
      nil
    end

    def removable_lines(start, body)
      lines = body.lines
      last_owned_line = lines.each_index.select do |index|
        index.zero? || lines[index].match?(/^\s*(?:path|enabled)\s*=/)
      end.max
      [start, start + last_owned_line + 1]
    end


    # The pruned document must equal the original minus exactly the removed
    # entries — nothing else may differ semantically.
    def valid_prune?(pruned, removed_indices)
      after = TomlRB.parse(pruned)
      before = Marshal.load(Marshal.dump(@document))
      skills = before["skills"]
      return false unless skills.is_a?(Hash)

      remaining = Array(skills["config"]).each_with_index.reject { |_entry, index| removed_indices.include?(index) }.map(&:first)
      if remaining.empty?
        skills.delete("config")
        before.delete("skills") if skills.empty?
      else
        skills["config"] = remaining
      end
      after == before
    rescue TomlRB::ParseError
      false
    end
  end
end
