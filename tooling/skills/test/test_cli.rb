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
    assert_includes out.string, "Exit codes: 0 success, 1 errors and gating findings, 2 usage error"
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

  def test_unknown_command_suggests_close_match_and_exits_two
    out = StringIO.new
    err = StringIO.new

    status = Skills::CLI.run(["depoy"], out: out, err: err, root: Dir.pwd)

    assert_equal 2, status
    assert_includes err.string, "unknown command 'depoy'"
    assert_includes err.string, "did you mean: deploy?"
    assert_includes err.string, "skills --help"
  end

  def test_help_for_unknown_command_suggests_close_match
    err = StringIO.new

    status = Skills::CLI.run(["help", "gathr"], out: StringIO.new, err: err, root: Dir.pwd)

    assert_equal 2, status
    assert_includes err.string, "did you mean: gather?"
  end

  def test_review_help_prints_the_canonical_criteria
    root = canonical_root
    out = StringIO.new

    status = Skills::CLI.run(["review", "--help"], out: out, err: StringIO.new, root: root)

    assert_equal 0, status
    assert_includes out.string, File.read(root.join("meta/manage-skills/references/review.md"))
  end

  def test_review_json_exposes_structured_findings_without_gating
    finding = Skills::Finding.new(
      :warning,
      "conciseness: Remove the repeated sentence (\"Repeat this\")",
      criterion: "conciseness",
      span: "Repeat this",
      suggestion: "Remove the repeated sentence"
    )
    out = StringIO.new

    status = with_review_manager([finding]) do
      Skills::CLI.run(["review", "alpha", "--json"], out: out, err: StringIO.new, root: canonical_root)
    end
    payload = JSON.parse(out.string)

    assert_equal 0, status
    assert_equal "conciseness", payload.fetch("findings").first.fetch("criterion")
    assert_equal "Repeat this", payload.fetch("findings").first.fetch("span")
    assert_equal "Remove the repeated sentence", payload.fetch("findings").first.fetch("suggestion")
  end

  def test_review_strict_gates_every_finding
    finding = Skills::Finding.new(:advice, "routing-quality: Name a realistic request", criterion: "routing-quality", span: "Review skills", suggestion: "Name a realistic request")

    status = with_review_manager([finding]) do
      Skills::CLI.run(["review", "alpha", "--strict"], out: StringIO.new, err: StringIO.new, root: canonical_root)
    end

    assert_equal 1, status
  end

  def test_review_missing_or_extra_name_is_a_usage_error
    missing_error = StringIO.new
    missing_status = Skills::CLI.run(["review", "--json"], out: StringIO.new, err: missing_error, root: canonical_root)

    extra_error = StringIO.new
    extra_status = with_review_manager([]) do
      Skills::CLI.run(["review", "alpha", "extra", "--json"], out: StringIO.new, err: extra_error, root: canonical_root)
    end

    assert_equal 2, missing_status
    assert_equal "missing argument: skill name", JSON.parse(missing_error.string).fetch("error")
    assert_equal 2, extra_status
    assert_equal "invalid argument: unexpected arguments: extra", JSON.parse(extra_error.string).fetch("error")
  end

  def test_review_operational_errors_use_the_json_error_envelope
    manager = Object.new
    manager.define_singleton_method(:review) { |_name, strict:| raise Skills::Reviewer::Error, "provider unavailable" }
    error = StringIO.new

    status = with_manager(manager) do
      Skills::CLI.run(["review", "alpha", "--json"], out: StringIO.new, err: error, root: canonical_root)
    end

    assert_equal 1, status
    assert_equal "provider unavailable", JSON.parse(error.string).fetch("error")
  end

  def test_doctor_remains_dispatched_after_review_is_added
    manager = Object.new
    calls = []
    manager.define_singleton_method(:doctor) do |fix:, apply:, project:|
      calls << [fix, apply, project]
      Skills::Result.new([], { kind: :doctor })
    end

    status = with_manager(manager) do
      Skills::CLI.run(["doctor", "--fix"], out: StringIO.new, err: StringIO.new, root: canonical_root)
    end

    assert_equal 0, status
    assert_equal [[true, false, nil]], calls
  end

  private

  def canonical_root
    Pathname(__dir__).join("../../..").expand_path
  end

  def with_review_manager(findings)
    manager = Object.new
    manager.define_singleton_method(:review) do |name, strict:|
      Skills::Result.new(findings, { kind: :review, name: name }, status: strict && findings.any? ? 1 : 0)
    end
    with_manager(manager) { yield }
  end

  def with_manager(manager)
    singleton = Skills::Manager.singleton_class
    singleton.alias_method(:new_without_review_test, :new)
    singleton.define_method(:new) { |*_, **_| manager }
    yield
  ensure
    singleton.alias_method(:new, :new_without_review_test)
    singleton.remove_method(:new_without_review_test)
  end

end
