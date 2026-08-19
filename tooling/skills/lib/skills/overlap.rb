# frozen_string_literal: true

module Skills
  class Overlap
    def initialize(catalog:)
      @catalog = catalog
    end

    def call(names:, scope:)
      missing = names.reject { |name| @catalog[name] }
      valid = names - missing
      pairs = valid.combination(2).filter_map do |left, right|
        left_tokens = tokens(@catalog[left])
        right_tokens = tokens(@catalog[right])
        shared = left_tokens & right_tokens
        next if shared.empty?

        union = left_tokens | right_tokens
        score = shared.length.to_f / union.length
        { left: left, right: right, score: score, shared: shared.sort } if score >= 0.25
      end
      findings = missing.map { |name| Finding.new(:error, "#{scope} scope references missing skill #{name}") }
      findings.concat(pairs.map { |pair| Finding.new(:warning, "#{pair[:left]} overlaps #{pair[:right]}: #{pair[:shared].join(", ")}") })
      Result.new(findings, { kind: :overlap, pairs: pairs })
    end

    private

    def tokens(skill)
      text = [skill.metadata["description"], *Array(skill.metadata["triggers"])].join(" ").downcase
      Set.new(text.scan(/[a-z][a-z0-9-]{2,}/))
    end
  end
end
