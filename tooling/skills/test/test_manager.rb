# frozen_string_literal: true

require_relative "test_helper"
require "skills"
require "stringio"

class SkillsManagerTest < Minitest::Test

  def test_catalogue_is_recursive_and_ignores_tooling_fixtures
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      nested = root.join("deep/category/beta")
      FileUtils.mkdir_p(nested)
      File.write(nested.join("SKILL.md"), "---\nname: beta\ndescription: beta\n---\n")
      fixture = root.join("tooling/skills/test/fixtures/ignored")
      FileUtils.mkdir_p(fixture)
      File.write(fixture.join("SKILL.md"), "---\nname: ignored\ndescription: ignored\n---\n")

      assert_equal %w[alpha beta], Skills::Manager.new(root: root).catalog.names
    end
  end

  def test_deploy_previews_then_applies_an_atomic_mirror_plan
    with_manager_sandbox do |root|
      write_skill(root, "alpha", files: { "note.txt" => "one" })
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      manager = Skills::Manager.new(root: root)

      preview = manager.deploy
      assert_equal [:add], preview.payload[:actions].map(&:type)
      refute_path_exists root.join("target/alpha")

      manager.deploy(apply: true)
      assert_equal "one", File.read(root.join("target/alpha/note.txt"))

      File.write(root.join("functional/alpha/note.txt"), "two")
      File.write(root.join("target/alpha/stale.txt"), "remove me")
      update = Skills::Manager.new(root: root).deploy
      assert_equal [:update], update.payload[:actions].map(&:type)

      Skills::Manager.new(root: root).deploy(apply: true)
      assert_equal "two", File.read(root.join("target/alpha/note.txt"))
      refute_path_exists root.join("target/alpha/stale.txt")
    end
  end

  def test_atomic_copy_restores_the_previous_skill_when_installation_fails
    with_manager_sandbox do |root|
      write_skill(root, "alpha", files: { "value.txt" => "new" })
      destination = root.join("target/alpha")
      FileUtils.mkdir_p(destination)
      File.write(destination.join("SKILL.md"), "old skill")
      File.write(destination.join("value.txt"), "old")
      mirror = Skills::Mirror.new(catalog: Skills::Manager.new(root: root).catalog, config: Skills::Config.load(root))
      original_rename = File.method(:rename)
      calls = 0
      rename = lambda do |from, to|
        calls += 1
        raise Errno::EIO, "simulated install failure" if calls == 2

        original_rename.call(from, to)
      end

      assert_raises(Errno::EIO) { mirror.send(:atomic_copy, root.join("functional/alpha"), destination, rename: rename) }

      assert_equal "old skill", File.read(destination.join("SKILL.md"))
      assert_equal "old", File.read(destination.join("value.txt"))
    end
  end

  def test_list_and_doctor_expose_target_drift
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      manager = Skills::Manager.new(root: root)

      assert_equal [:add], manager.list.payload.fetch(:rows).first[:drift]
      assert_includes manager.doctor.findings.map(&:message), "#{root.join("target/alpha")}: missing resolved skill"
    end
  end

  def test_list_reports_resolved_project_and_suite_membership
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      write_skill(root, "beta")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      inherited = root.join("projects/inherited")
      custom = root.join("projects/custom")
      FileUtils.mkdir_p(inherited.join(".agents"))
      FileUtils.mkdir_p(custom.join(".agents"))
      File.write(inherited.join(".agents/skills-manifest.toml"), "add = []\nexclude = []\n")
      File.write(custom.join(".agents/skills-manifest.toml"), "add = [\"beta\"]\nexclude = [\"alpha\"]\n")
      agents = root.parent.join("agents/agents")
      FileUtils.mkdir_p(agents)
      File.write(agents.join("build.md"), "---\nskills: [alpha, beta]\n---\n")

      rows = Skills::Manager.new(root: root).list.payload.fetch(:rows).to_h { |row| [row[:name], row] }

      assert_equal [inherited.to_s], rows.fetch("alpha").fetch(:projects)
      assert_equal [custom.to_s], rows.fetch("beta").fetch(:projects)
      assert_equal ["build"], rows.fetch("alpha").fetch(:suites)
      assert_equal ["build"], rows.fetch("beta").fetch(:suites)
    end
  end

  def test_doctor_reports_all_missing_project_manifest_references
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      project = root.parent.parent.join("projects/example")
      FileUtils.mkdir_p(project.join(".agents"))
      manifest = project.join(".agents/skills-manifest.toml")
      File.write(manifest, "add = [\"missing-add\"]\nexclude = [\"missing-exclude\"]\n")
      config_path = root.join("tooling/skills/skills.toml")
      config = File.read(config_path).sub("[[target]]", "project_roots = [#{project.parent.to_s.inspect}]\n\n[[target]]")
      File.write(config_path, config)

      messages = Skills::Manager.new(root: root).doctor.findings.map(&:message)

      assert_includes messages, "#{manifest}: project manifest references missing skill missing-add"
      assert_includes messages, "#{manifest}: project manifest references missing skill missing-exclude"
    end
  end

  def test_suite_overlap_reports_missing_members_and_continues
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      write_skill(root, "beta")
      agents = root.parent.join("agents/agents")
      FileUtils.mkdir_p(agents)
      File.write(agents.join("build.md"), "---\nskills: [alpha, missing, beta]\n---\n")

      result = Skills::Manager.new(root: root).overlap(scope: "suite", suite: "build")

      assert_includes result.findings.map(&:message), "suite scope references missing skill missing"
      assert_equal 1, result.exit_code
      assert_equal [], result.payload.fetch(:pairs)
    end
  end

  def test_suite_overlap_reports_malformed_profile
    with_manager_sandbox do |root|
      agents = root.parent.join("agents/agents")
      FileUtils.mkdir_p(agents)
      profile = agents.join("build.md")
      File.write(profile, "---\nskills: not-a-list\n---\n")

      result = Skills::Manager.new(root: root).overlap(scope: "suite", suite: "build")

      assert result.findings.any? { |finding| finding.message.include?(profile.to_s) && finding.message.include?("skills must be an array") }
      assert_equal 1, result.exit_code
      assert_empty result.payload.fetch(:pairs)
    end
  end

  def test_lint_reports_advisory_relative_reference_and_trigger_findings
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("functional/alpha/SKILL.md"), "---\nname: alpha\ndescription: alpha\n---\n[missing](references/nope.md)\n")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")

      findings = Skills::Manager.new(root: root).lint.findings
      messages = findings.map(&:message)

      assert_includes messages, "#{root.join("functional/alpha")}: global skill has no explicit triggers"
      assert_includes messages, "#{root.join("functional/alpha")}: missing relative reference references/nope.md"
      assert_equal :error, findings.find { |finding| finding.message.end_with?("references/nope.md") }.severity
    end
  end

  def test_deploy_reports_dead_manifest_entries_without_skipping_valid_work
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\", \"missing\"]\n")

      result = Skills::Manager.new(root: root).deploy

      assert_equal ["alpha"], result.payload[:names]
      assert_equal [:add], result.payload[:actions].map(&:type)
      assert_includes result.findings.map(&:message), "global manifest references missing skill missing"
      assert_equal 1, result.exit_code
    end
  end

  def test_lint_blocks_frontmatter_and_profile_reference_failures
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("functional/alpha/SKILL.md"), "not frontmatter\n")
      agents = root.parent.join("agents/agents")
      FileUtils.mkdir_p(agents)
      File.write(agents.join("build.md"), "---\nskills: [missing]\n---\n")

      messages = Skills::Manager.new(root: root).lint.findings.map(&:message)

      assert_includes messages, "#{root.join("functional/alpha")}: missing YAML frontmatter"
      assert_includes messages, "#{agents.join("build.md")}: profile references missing skill missing"
    end
  end

  def test_lint_preserves_legacy_manifest_and_dependency_checks
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      write_skill(root, "beta")
      File.write(root.join("functional/alpha/SKILL.md"), "---\nname: alpha\ndescription: alpha\n---\nUses `beta`.\n")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\", \"alpha\"]\n")

      messages = Skills::Manager.new(root: root).lint.findings.map(&:message)

      assert_includes messages, "global manifest contains duplicate skill names: alpha"
      assert_includes messages, "global dependency outside manifest: alpha -> beta"
    end
  end

  def test_lint_blocks_non_global_name_mismatch
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("functional/alpha/SKILL.md"), "---\nname: other\ndescription: alpha\n---\n")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")

      mismatch = Skills::Manager.new(root: root).lint.findings.find { |finding| finding.message.include?("does not match directory") }

      refute_nil mismatch
      assert_equal :error, mismatch.severity
    end
  end

  def test_project_disable_preserves_the_global_minus_exclude_contract
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      write_skill(root, "beta")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\", \"beta\"]\n")
      project = root.join("project")
      FileUtils.mkdir_p(project)
      manager = Skills::Manager.new(root: root)

      result = manager.disable("beta", project: project, apply: true)

      assert_equal ["beta"], result.payload[:exclude]
      assert_equal ["alpha"], Skills::Manager.new(root: root).resolved(project: project)
    end
  end

  def test_doctor_reports_missing_profile_skills_without_writing_the_profile_repo
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      agents = root.parent.join("agents/agents")
      FileUtils.mkdir_p(agents)
      File.write(agents.join("build.md"), "---\nskills: [alpha, missing]\n---\n")

      findings = Skills::Manager.new(root: root).doctor.findings

      assert_includes findings.map(&:message), "#{agents.join("build.md")}: profile references missing skill missing"
      assert_path_exists agents.join("build.md")
    end
  end

  def test_fetch_and_update_keep_a_vendored_skill_and_provenance_in_sync
    with_manager_sandbox do |root|
      upstream = root.join("upstream")
      write_upstream_skill(upstream, "external", "first")
      git(upstream, "init", "--quiet")
      git(upstream, "config", "user.email", "test@example.com")
      git(upstream, "config", "user.name", "Test")
      git(upstream, "config", "commit.gpgsign", "false")
      git(upstream, "add", ".")
      git(upstream, "commit", "--quiet", "-m", "initial")

      manager = Skills::Manager.new(root: root)
      listing = manager.fetch(upstream.to_s, list: true)
      assert_equal ["external"], listing.payload[:candidates]
      planned = manager.fetch(upstream.to_s, skill: "external")
      assert_equal "would fetch", planned.payload[:action]
      refute_path_exists root.join("vendor/external")

      fetched = manager.fetch(upstream.to_s, apply: true)
      assert_empty fetched.findings
      assert_equal "first", File.read(root.join("vendor/external/value.txt"))
      assert_includes File.read(root.join("SOURCES.toml")), "[external]"

      File.write(upstream.join("external/value.txt"), "second")
      git(upstream, "add", ".")
      git(upstream, "commit", "--quiet", "-m", "update")
      File.write(root.join("vendor/external/stale.txt"), "remove")

      preview = Skills::Manager.new(root: root).update("external")
      assert_equal "would update", preview.payload[:action]
      assert_equal true, preview.payload[:content_changed]
      assert_path_exists root.join("vendor/external/stale.txt")

      updated = Skills::Manager.new(root: root).update("external", apply: true)
      assert_empty updated.findings
      assert_equal "second", File.read(root.join("vendor/external/value.txt"))
      refute_path_exists root.join("vendor/external/stale.txt")

      FileUtils.rm_rf(root.join("vendor"))
      rehydrated = Skills::Manager.new(root: root).fetch_all(apply: true)

      assert_empty rehydrated.findings
      assert_equal "second", File.read(root.join("vendor/external/value.txt"))
      source = TomlRB.load_file(root.join("SOURCES.toml")).fetch("external")
      assert_equal upstream.to_s, source.fetch("url")
      assert_equal "external", source.fetch("path")
    end
  end

  def test_cli_accepts_global_and_rejects_it_with_project
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      out = StringIO.new
      err = StringIO.new

      status = Skills::CLI.run(["list", "--global"], out: out, err: err, root: root)
      assert_equal 0, status

      status = Skills::CLI.run(["list", "--global", "--project", root.to_s], out: out, err: err, root: root)
      assert_equal 2, status
      assert_includes err.string, "--global and --project are mutually exclusive"
    end
  end

  def test_missing_manifest_never_removes_existing_target_skills
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      target = root.join("target/alpha")
      FileUtils.mkdir_p(target)
      File.write(target.join("SKILL.md"), "deployed")

      result = Skills::Manager.new(root: root).deploy(apply: true)

      assert_equal false, result.payload[:applied]
      assert result.findings.any? { |finding| finding.message.include?("manifest is missing") }
      assert_path_exists target
    end
  end

  def test_empty_manifest_refuses_destructive_cleanup
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = []\n")
      target = root.join("target/alpha")
      FileUtils.mkdir_p(target)
      File.write(target.join("SKILL.md"), "deployed")

      result = Skills::Manager.new(root: root).deploy(apply: true)

      assert_empty result.payload[:actions]
      assert_equal false, result.payload[:applied]
      assert_path_exists target
    end
  end

  def test_project_deploy_uses_existing_project_agents_target
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      project = root.join("project")
      FileUtils.mkdir_p(project)

      preview = Skills::Manager.new(root: root).deploy(project: project)

      assert_equal [project.join(".agents/skills/alpha")], preview.payload[:actions].map(&:target)
      assert_empty preview.findings
    end
  end

  def test_project_mutations_reject_missing_project_root
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      missing = root.join("missing-project")

      result = Skills::Manager.new(root: root).enable("alpha", project: missing, apply: true)

      assert result.findings.any? { |finding| finding.message.include?("project does not exist") }
      refute_path_exists missing
    end
  end

  def test_gather_auto_discovers_configured_target
    with_manager_sandbox do |root|
      source = root.join("target/stray")
      FileUtils.mkdir_p(source)
      File.write(source.join("SKILL.md"), "---\nname: stray\ndescription: stray\n---\n")
      manager = Skills::Manager.new(root: root)

      preview = manager.gather("stray")
      refute_path_exists root.join("personal/stray")
      assert_equal source.to_s, preview.payload[:source]

      applied = manager.gather("stray", apply: true)
      assert_empty applied.findings
      assert_path_exists root.join("personal/stray/SKILL.md")
    end
  end

  def test_gather_accepts_a_target_root_as_from
    with_manager_sandbox do |root|
      source_root = root.join("wild")
      FileUtils.mkdir_p(source_root.join("stray"))
      File.write(source_root.join("stray/SKILL.md"), "---\nname: stray\ndescription: stray\n---\n")

      result = Skills::Manager.new(root: root).gather("stray", from: source_root)

      assert_equal source_root.join("stray").to_s, result.payload[:source]
    end
  end

  def test_gather_rejects_destination_escape
    with_manager_sandbox do |root|
      source = root.join("wild")
      FileUtils.mkdir_p(source)
      File.write(source.join("SKILL.md"), "---\nname: stray\ndescription: stray\n---\n")

      result = Skills::Manager.new(root: root).gather("stray", from: source, category: "../outside", apply: true)

      assert result.findings.any? { |finding| finding.message.include?("invalid category") }
      refute_path_exists root.parent.join("outside/stray")
    end
  end

  def test_malformed_profile_is_reported_by_doctor
    with_manager_sandbox do |root|
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      write_skill(root, "alpha")
      profiles = root.parent.join("agents/agents")
      FileUtils.mkdir_p(profiles)
      profile = profiles.join("broken.md")
      File.write(profile, "---\nskills: [alpha\n---\n")

      messages = Skills::Manager.new(root: root).doctor.findings.map(&:message)

      assert messages.any? { |message| message.include?(profile.to_s) && message.include?("invalid YAML") }
    end
  end

  def test_duplicate_catalogue_names_block_lint_and_deploy
    with_manager_sandbox do |root|
      %w[first second].each do |category|
        skill = root.join(category, "alpha")
        FileUtils.mkdir_p(skill)
        File.write(skill.join("SKILL.md"), "---\nname: alpha\ndescription: alpha\n---\n")
      end
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      manager = Skills::Manager.new(root: root)

      assert manager.lint.findings.any? { |finding| finding.message.include?("duplicate skill alpha") }
      deploy = manager.deploy(apply: true)
      assert_equal false, deploy.payload[:applied]
      assert deploy.findings.any? { |finding| finding.message.include?("duplicate skill alpha") }
    end
  end

  def test_global_enable_and_disable_preview_then_apply
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      write_skill(root, "beta")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      manager = Skills::Manager.new(root: root)

      preview = manager.enable("beta")
      assert_equal %w[alpha beta], preview.payload[:skills]
      assert_equal ["alpha"], Skills::Config.load(root).manifest_skills

      manager.enable("beta", apply: true)
      assert_equal %w[alpha beta], Skills::Config.load(root).manifest_skills
      manager.disable("alpha", apply: true)
      assert_equal ["beta"], Skills::Config.load(root).manifest_skills
    end
  end

  def test_lint_strict_promotes_advisories_to_errors
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")

      findings = Skills::Manager.new(root: root).lint(strict: true).findings

      assert findings.any?
      assert findings.all? { |finding| finding.severity == :error }
    end
  end

  def test_doctor_aggregates_independent_surface_failures
    with_manager_sandbox do |root|
      File.write(root.join("global-manifest.toml"), "skills = [\n")
      profiles = root.parent.join("agents/agents")
      FileUtils.mkdir_p(profiles)
      profile = profiles.join("broken.md")
      File.write(profile, "---\nskills: [alpha\n---\n")
      project = root.join("project")
      FileUtils.mkdir_p(project.join(".agents"))
      File.write(project.join(".agents/skills-manifest.toml"), "add = [\"missing\"]\nexclude = []\n")
      home = root.join("home")
      FileUtils.mkdir_p(home.join(".codex"))
      File.write(home.join(".codex/config.toml"), "not [ valid toml\n")

      messages = Skills::Manager.new(root: root, home: home).doctor(project: project).findings.map(&:message)

      assert messages.any? { |message| message.include?("invalid TOML") && message.include?("global-manifest") }
      assert messages.any? { |message| message.include?(profile.to_s) && message.include?("invalid YAML") }
      assert messages.any? { |message| message.include?("project manifest references missing skill missing") }
      assert messages.any? { |message| message.include?("Codex config is unparsable") }
    end
  end

  def test_doctor_fix_prunes_dead_project_manifest_references
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      File.write(root.join("global-manifest.toml"), "skills = [\"alpha\"]\n")
      project = root.join("project")
      FileUtils.mkdir_p(project.join(".agents"))
      manifest = project.join(".agents/skills-manifest.toml")
      File.write(manifest, "add = [\"missing\"]\nexclude = []\n")
      manager = Skills::Manager.new(root: root)

      preview = manager.doctor(fix: true, project: project)
      assert_equal "missing", preview.payload[:planned_project_references].first[:name]
      assert_includes File.read(manifest), "missing"

      applied = manager.doctor(fix: true, apply: true, project: project)
      assert_equal "missing", applied.payload[:pruned_project_references].first[:name]
      refute_includes File.read(manifest), "missing"
    end
  end

  def test_review_uses_injected_reviewer_and_only_strict_gates_findings
    with_manager_sandbox do |root|
      write_skill(root, "alpha")
      received = []
      finding = Skills::Finding.new(:advice, "routing-quality: Name a request", criterion: "routing-quality", span: "description: alpha", suggestion: "Name a request")
      reviewer = lambda do |skill|
        received << skill
        [finding]
      end
      manager = Skills::Manager.new(root: root, reviewer: reviewer)

      advisory = manager.review("alpha")
      strict = manager.review("alpha", strict: true)

      assert_equal ["alpha", "alpha"], received.map(&:name)
      assert_equal 0, advisory.exit_code
      assert_equal 1, strict.exit_code
      assert_equal finding, advisory.findings.first
    end
  end

  def test_review_rejects_unknown_and_vendored_skills_without_calling_reviewer
    with_manager_sandbox do |root|
      directory = root.join("vendor/external")
      FileUtils.mkdir_p(directory)
      File.write(directory.join("SKILL.md"), "---\nname: external\ndescription: external\n---\n")
      reviewer = ->(_skill) { flunk "reviewer must not receive invalid targets" }
      manager = Skills::Manager.new(root: root, reviewer: reviewer)

      unknown = manager.review("missing")
      vendored = manager.review("external")

      assert_equal 1, unknown.exit_code
      assert_equal "unknown skill missing", unknown.findings.first.message
      assert_equal 1, vendored.exit_code
      assert_equal "cannot review vendored skill external", vendored.findings.first.message
    end
  end

  def test_review_rejects_duplicate_canonical_names_without_calling_reviewer
    with_manager_sandbox do |root|
      paths = %w[first second].map do |category|
        directory = root.join(category, "alpha")
        FileUtils.mkdir_p(directory)
        File.write(directory.join("SKILL.md"), "---\nname: alpha\ndescription: alpha\n---\n")
        directory
      end
      reviewer = ->(_skill) { flunk "reviewer must not receive an ambiguous target" }

      result = Skills::Manager.new(root: root, reviewer: reviewer).review("alpha")

      assert_equal 1, result.exit_code
      assert_includes result.findings.first.message, "cannot review duplicate skill alpha"
      paths.each { |path| assert_includes result.findings.first.message, path.to_s }
    end
  end

  def test_review_protocol_keeps_existing_findings_and_results_compatible
    finding = Skills::Finding.new(:warning, "existing finding")
    result = Skills::Result.new([finding], nil)

    assert_nil finding.criterion
    assert_nil finding.span
    assert_nil finding.suggestion
    assert_equal 1, result.exit_code
  end

  private

  def write_upstream_skill(root, name, value)
    directory = root.join(name)
    FileUtils.mkdir_p(directory)
    File.write(directory.join("SKILL.md"), "---\nname: #{name}\ndescription: #{name}\n---\n")
    File.write(directory.join("value.txt"), value)
  end

end
