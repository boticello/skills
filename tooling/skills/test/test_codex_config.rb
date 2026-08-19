# frozen_string_literal: true

require_relative "test_helper"
require "skills"

class CodexConfigTest < Minitest::Test
  def with_codex_sandbox(manifest: ["alpha"])
    Dir.mktmpdir("skills-codex-config") do |directory|
      root = Pathname(directory).join("repos/skills")
      FileUtils.mkdir_p(root.join("tooling/skills"))
      File.write(root.join("tooling/skills/skills.toml"), "ignore = []\n")
      manifest_list = manifest.map(&:inspect).join(", ")
      File.write(root.join("global-manifest.toml"), "skills = [#{manifest_list}]\n")
      home = Pathname(directory).join("home")
      FileUtils.mkdir_p(home.join(".codex"))
      config_path = home.join(".codex/config.toml")
      %w[alpha beta].each do |name|
        skill = home.join(".agents/skills/#{name}")
        FileUtils.mkdir_p(skill)
        File.write(skill.join("SKILL.md"), "---\nname: #{name}\n---\n")
      end
      yield root, home, config_path
    end
  end

  def sample_config(home)
    <<~TOML
      # Codex configuration — comments must survive pruning.
      model = "gpt-5.6-terra"

      [[skills.config]]
      path = "#{home}/.agents/skills/gone/SKILL.md"
      enabled = false

      [[skills.config]]
      path = "#{home}/.agents/skills/alpha/SKILL.md"
      enabled = false

      [[skills.config]]
      path = "#{home}/.agents/skills/beta/SKILL.md"
      enabled = false

      [[skills.config]]
      path = "#{home}/.agents/skills/gone-with-extras/SKILL.md"
      enabled = false
      model = "o4-mini"

      [mcp.servers.filesystem]
      path = "#{home}/nonexistent-mcp-path"
    TOML
  end

  def test_classification_separates_dead_conflict_stray_and_ignores_other_sections
    with_codex_sandbox do |_root, home, config_path|
      File.write(config_path, sample_config(home))
      codex = Skills::CodexConfig.load(config_path)

      classes = codex.classify(["alpha"])
      assert_equal %w[gone gone-with-extras], classes[:dead].map(&:name).sort
      assert_equal %w[alpha], classes[:conflict].map(&:name)
      assert_equal %w[beta], classes[:stray].map(&:name)
      assert_empty classes[:enabled]
      assert_empty codex.findings
    end
  end

  def test_prune_removes_only_simple_dead_entries_and_preserves_the_rest
    with_codex_sandbox do |_root, home, config_path|
      File.write(config_path, sample_config(home))
      codex = Skills::CodexConfig.load(config_path)

      pruned, removed = codex.prune_text
      assert_equal ["#{home}/.agents/skills/gone/SKILL.md"], removed
      refute_includes pruned, "gone/SKILL.md"
      assert_includes pruned, "gone-with-extras/SKILL.md", "unknown-key dead entry must stay"
      assert_includes pruned, "alpha/SKILL.md"
      assert_includes pruned, "beta/SKILL.md"
      assert_includes pruned, "# Codex configuration", "header comment must survive"
      assert_includes pruned, "[mcp.servers.filesystem]", "unrelated sections must survive"
      assert_equal 3, Array(TomlRB.parse(pruned).dig("skills", "config")).length
    end
  end

  def test_prune_preserves_extended_entry_when_a_simple_entry_has_the_same_path
    with_codex_sandbox do |_root, home, config_path|
      path = "#{home}/.agents/skills/gone/SKILL.md"
      File.write(config_path, <<~TOML)
        [[skills.config]]
        path = "#{path}"
        enabled = false

        [[skills.config]]
        path = "#{path}"
        enabled = false
        model = "keep-me"
      TOML

      pruned, removed = Skills::CodexConfig.load(config_path).prune_text

      assert_equal [path], removed
      assert_includes pruned, "model = \"keep-me\""
      entries = Array(TomlRB.parse(pruned).dig("skills", "config"))
      assert_equal 1, entries.length
      assert_equal "keep-me", entries.first.fetch("model")
    end
  end

  def test_prune_preserves_dead_entry_without_an_explicit_enabled_key
    with_codex_sandbox do |_root, home, config_path|
      path = "#{home}/.agents/skills/gone/SKILL.md"
      File.write(config_path, "[[skills.config]]\npath = #{path.inspect}\n")

      pruned, removed = Skills::CodexConfig.load(config_path).prune_text

      assert_empty removed
      assert_includes pruned, path
    end
  end

  def test_prune_refuses_unparsable_config
    with_codex_sandbox do |_root, _home, config_path|
      File.write(config_path, "not [ valid toml\n")
      codex = Skills::CodexConfig.load(config_path)

      assert codex.findings.any? { |finding| finding.severity == :error }
      assert_equal [nil, []], codex.prune_text
    end
  end

  def test_doctor_reports_and_fix_prunes_with_backup
    with_codex_sandbox do |root, home, config_path|
      File.write(config_path, sample_config(home))
      state = home.join("state")
      previous = ENV["XDG_STATE_HOME"]
      ENV["XDG_STATE_HOME"] = state.to_s
      begin
        manager = Skills::Manager.new(root: root, home: home)

        report = manager.doctor
        assert report.findings.any? { |finding| finding.message.include?("dead skill path") && finding.message.include?("gone/SKILL.md") }
        assert report.findings.any? { |finding| finding.message.include?("alpha is in the global manifest but disabled in Codex") }

        preview = manager.doctor(fix: true)
        assert_equal({ fix_requested: true, fixed: false }, preview.payload)
        assert_includes File.read(config_path), "gone/SKILL.md", "fix without --apply must not write"

        fixed = manager.doctor(fix: true, apply: true)
        assert_equal ["#{home}/.agents/skills/gone/SKILL.md"], fixed.payload[:pruned_codex_paths]
        refute fixed.findings.any? { |finding| finding.message.include?("gone/SKILL.md") && finding.message.include?("prune with") }
        content = File.read(config_path)
        assert_includes content, "gone-with-extras/SKILL.md"
        refute_includes content, "gone/SKILL.md"
        assert Dir.glob(state.join("skills-backups/*/codex-config.toml")).one?, "a timestamped backup must exist"
      ensure
        ENV["XDG_STATE_HOME"] = previous
      end
    end
  end
end
