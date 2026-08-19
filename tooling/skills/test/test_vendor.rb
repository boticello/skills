# frozen_string_literal: true

require_relative "test_helper"
require "skills"

class SkillsVendorTest < Minitest::Test
  def test_production_load_includes_tmpdir
    project = Pathname(__dir__).parent
    stdout, stderr, status = Open3.capture3(
      Gem.ruby, "-Ilib", "-e", 'require "skills"; print Dir.respond_to?(:mktmpdir)',
      chdir: project.to_s
    )

    assert_predicate status, :success?, stderr
    assert_equal "true", stdout
  end

  def test_fetch_all_rehydrates_the_recorded_commit
    with_manager_sandbox do |root|
      upstream = root.join("upstream")
      write_upstream_skill(upstream, "external", "one")
      initialize_repository(upstream)
      first_commit = commit(upstream, "first")
      manager = Skills::Manager.new(root: root)
      fetched = manager.fetch(upstream.to_s, apply: true)
      assert_empty fetched.findings

      File.write(upstream.join("external/value.txt"), "two")
      commit(upstream, "second")
      FileUtils.rm_rf(root.join("vendor"))

      rehydrated = Skills::Manager.new(root: root).fetch_all(apply: true)

      assert_empty rehydrated.findings
      assert_equal "one", File.read(root.join("vendor/external/value.txt"))
      assert_equal first_commit, TomlRB.load_file(root.join("SOURCES.toml")).dig("external", "commit")
    end
  end

  def test_update_rediscovers_a_root_level_skill
    with_manager_sandbox do |root|
      upstream = root.join("root-example")
      FileUtils.mkdir_p(upstream)
      File.write(upstream.join("SKILL.md"), "---\nname: root-example\ndescription: root\n---\n")
      File.write(upstream.join("value.txt"), "one")
      initialize_repository(upstream)
      commit(upstream, "first")
      manager = Skills::Manager.new(root: root)
      fetched = manager.fetch(upstream.to_s, apply: true)
      assert_empty fetched.findings

      File.write(upstream.join("value.txt"), "two")
      commit(upstream, "second")
      updated = Skills::Manager.new(root: root).update("root-example", apply: true)

      assert_empty updated.findings
      assert_equal "two", File.read(root.join("vendor/root-example/value.txt"))
    end
  end

  def test_fetch_all_reports_bad_sources_and_continues_valid_rehydration
    with_manager_sandbox do |root|
      upstream = root.join("upstream")
      write_upstream_skill(upstream, "external", "one")
      initialize_repository(upstream)
      good_commit = commit(upstream, "first")
      File.write(root.join("SOURCES.toml"), TomlRB.dump({
        "broken" => { "url" => upstream.to_s, "commit" => "unverified" },
        "external" => { "url" => upstream.to_s, "commit" => good_commit, "path" => "external" }
      }))

      result = Skills::Manager.new(root: root).fetch_all(apply: true)

      assert result.findings.any? { |finding| finding.message.include?("broken") }
      assert_equal true, result.payload[:partial]
      assert_path_exists root.join("vendor/external/SKILL.md")
    end
  end

  def test_fetch_preserves_existing_sources_comment_header
    with_manager_sandbox do |root|
      upstream = root.join("upstream")
      write_upstream_skill(upstream, "external", "one")
      initialize_repository(upstream)
      commit(upstream, "first")
      header = "# custom provenance instructions\n# keep this text byte-for-byte\n\n"
      File.write(root.join("SOURCES.toml"), "#{header}[existing]\nurl = \"https://example.com/repo\"\ncommit = \"#{"a" * 40}\"\n")

      result = Skills::Manager.new(root: root).fetch(upstream.to_s, apply: true)

      assert_empty result.findings
      assert File.read(root.join("SOURCES.toml")).start_with?(header)
    end
  end

  private

  def write_upstream_skill(root, name, value)
    directory = root.join(name)
    FileUtils.mkdir_p(directory)
    File.write(directory.join("SKILL.md"), "---\nname: #{name}\ndescription: #{name}\n---\n")
    File.write(directory.join("value.txt"), value)
  end

  def initialize_repository(root)
    git(root, "init", "--quiet")
    git(root, "config", "user.email", "test@example.com")
    git(root, "config", "user.name", "Test")
    git(root, "config", "commit.gpgsign", "false")
  end

  def commit(root, message)
    git(root, "add", ".")
    git(root, "commit", "--quiet", "-m", message)
    stdout, stderr, status = Open3.capture3("git", "-C", root.to_s, "rev-parse", "HEAD")
    assert_predicate status, :success?, stderr
    stdout.strip
  end
end
