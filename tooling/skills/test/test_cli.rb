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

  def test_top_level_help_lists_every_command_with_summaries
    out = StringIO.new

    status = Skills::CLI.run(["--help"], out: out, err: StringIO.new, root: Dir.pwd)

    assert_equal 0, status
    Skills::CLI::COMMANDS.each_key do |name|
      assert_includes out.string, name
    end
    assert_includes out.string, "pass --apply to write"
    assert_includes out.string, "Exit codes: 0 clean, 1 findings, 2 usage error"
  end

  def test_every_registered_command_has_a_dispatch_handler
    cli = Skills::CLI.new([], out: StringIO.new, err: StringIO.new, root: Dir.pwd)

    Skills::CLI::COMMANDS.each_value do |spec|
      assert cli.respond_to?(spec.fetch(:handler), true)
    end
  end

  def test_command_help_shows_only_relevant_options
    out = StringIO.new

    status = Skills::CLI.run(["gather", "--help"], out: out, err: StringIO.new, root: Dir.pwd)

    assert_equal 0, status
    assert_includes out.string, "Usage: skills gather <name>"
    assert_includes out.string, "--from PATH"
    assert_includes out.string, "--category NAME"
    refute_includes out.string, "--ref REF"
    assert_includes out.string, "Examples:"
  end

  def test_help_subcommand_matches_flag_help
    flag_out = StringIO.new
    subcommand_out = StringIO.new

    Skills::CLI.run(["fetch", "--help"], out: flag_out, err: StringIO.new, root: Dir.pwd)
    Skills::CLI.run(["help", "fetch"], out: subcommand_out, err: StringIO.new, root: Dir.pwd)

    assert_equal flag_out.string, subcommand_out.string
  end

  def test_unknown_command_suggests_close_match_and_prints_command_table
    out = StringIO.new
    err = StringIO.new

    status = Skills::CLI.run(["depoy"], out: out, err: err, root: Dir.pwd)

    assert_equal 2, status
    assert_includes err.string, "unknown command 'depoy'"
    assert_includes err.string, "did you mean: deploy?"
    assert_includes err.string, "Commands:"
    assert_includes err.string, "gather <name>"
  end

  def test_help_for_unknown_command_suggests_close_match
    err = StringIO.new

    status = Skills::CLI.run(["help", "gathr"], out: StringIO.new, err: err, root: Dir.pwd)

    assert_equal 2, status
    assert_includes err.string, "did you mean: gather?"
  end

  def test_invalid_option_prints_command_help
    with_manager_sandbox do |root|
      err = StringIO.new

      status = Skills::CLI.run(["gather", "--bogus"], out: StringIO.new, err: err, root: root)

      assert_equal 2, status
      assert_includes err.string, "invalid option: --bogus"
      assert_includes err.string, "Usage: skills gather <name>"
      assert_includes err.string, "--from PATH"
      refute_includes err.string, "--ref REF"
    end
  end

  def test_missing_argument_prints_command_help
    with_manager_sandbox do |root|
      err = StringIO.new

      status = Skills::CLI.run(["gather"], out: StringIO.new, err: err, root: root)

      assert_equal 2, status
      assert_includes err.string, "missing argument: skill name"
      assert_includes err.string, "Usage: skills gather <name>"
    end
  end

  def test_json_usage_error_remains_machine_readable
    with_manager_sandbox do |root|
      err = StringIO.new

      status = Skills::CLI.run(["gather", "--json"], out: StringIO.new, err: err, root: root)
      payload = JSON.parse(err.string)

      assert_equal 2, status
      assert_equal "missing argument: skill name", payload.fetch("error")
      assert_equal 2, payload.fetch("exit_code")
    end
  end

end
