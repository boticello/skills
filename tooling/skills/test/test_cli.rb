# frozen_string_literal: true

require_relative "test_helper"
require "skills"
require "stringio"

class SkillsCliTest < Minitest::Test
  def test_deploy_json_contains_structured_actions
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      out = StringIO.new

      status = Skills::CLI.run(["deploy", "--json"], out: out, err: StringIO.new, root: root)
      payload = JSON.parse(out.string)
      action = payload.fetch("payload").fetch("actions").first

      assert_equal 0, status
      assert_equal "add", action.fetch("type")
      assert_equal "alpha", action.fetch("name")
      assert_kind_of String, action.fetch("source")
      assert_kind_of String, action.fetch("target")
    end
  end

  def test_overlap_human_output_renders_pairs
    with_manager_sandbox do |root|
      %w[alpha beta].each do |name|
        write_skill(root, name)
        File.write(root.join("functional", name, "SKILL.md"), <<~SKILL)
          ---
          name: #{name}
          description: shared trigger words
          triggers: [shared, trigger, words]
          ---
        SKILL
      end
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\", \"beta\"]\n")
      out = StringIO.new

      status = Skills::CLI.run(["overlap"], out: out, err: StringIO.new, root: root)

      assert_equal 1, status
      assert_includes out.string, "alpha\tbeta\tscore="
      assert_includes out.string, "shared="
    end
  end

  def test_warning_only_result_exits_one
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")

      status = Skills::CLI.run(["lint"], out: StringIO.new, err: StringIO.new, root: root)

      assert_equal 1, status
    end
  end

  def test_unexpected_arguments_are_usage_errors
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      err = StringIO.new

      status = Skills::CLI.run(["enable", "alpha", "extra"], out: StringIO.new, err: err, root: root)

      assert_equal 2, status
      assert_includes err.string, "unexpected arguments"
    end
  end

  def test_overlap_resolves_project_and_suite_scopes
    with_manager_sandbox do |root|
      %w[alpha beta].each do |name|
        write_skill(root, name)
        File.write(root.join("functional", name, "SKILL.md"), "---\nname: #{name}\ndescription: shared trigger words\ntriggers: [shared, trigger, words]\n---\n")
      end
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      project = root.join("project")
      FileUtils.mkdir_p(project.join(".agents"))
      File.write(project.join(".agents/skills-manifest.toml"), "add = [\"beta\"]\nexclude = []\n")
      profiles = root.parent.join("agents/agents")
      FileUtils.mkdir_p(profiles)
      File.write(profiles.join("build.md"), "---\nskills: [alpha, beta]\n---\n")
      manager = Skills::Manager.new(root: root)

      project_pairs = manager.overlap(scope: "project", project: project).payload[:pairs]
      suite_pairs = manager.overlap(scope: "suite", suite: "build").payload[:pairs]

      assert_equal [%w[alpha beta]], project_pairs.map { |pair| [pair[:left], pair[:right]] }
      assert_equal [%w[alpha beta]], suite_pairs.map { |pair| [pair[:left], pair[:right]] }
    end
  end

  def test_project_overlap_requires_project_option
    with_manager_sandbox do |root|
      err = StringIO.new

      status = Skills::CLI.run(
        ["overlap", "--scope", "project", "--json"],
        out: StringIO.new,
        err: err,
        root: root
      )

      assert_equal 2, status
      assert_equal "--project is required for --scope project", JSON.parse(err.string).fetch("error")
    end
  end

end
