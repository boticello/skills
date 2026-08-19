# frozen_string_literal: true

require_relative "test_helper"
require "skills"

class SkillsMirrorTest < Minitest::Test
  def test_removals_are_backed_up_and_allowlisted_entries_survive
    with_manager_sandbox do |root|
      File.write(root.join("allowlist.txt"), "keep-*\n")
      %w[remove-me keep-plugin].each do |name|
        directory = root.join("target", name)
        FileUtils.mkdir_p(directory)
        File.write(directory.join("SKILL.md"), name)
      end
      config = Skills::Config.load(root)
      mirror = Skills::Mirror.new(catalog: Skills::Catalog.new(config), config: config)
      actions = mirror.plan([])
      backups = root.join("backups")

      findings = mirror.apply(actions, backup_root: backups)

      assert_empty findings
      refute_path_exists root.join("target/remove-me")
      assert_path_exists root.join("target/keep-plugin")
      assert Dir.glob(backups.join("*/remove-me/SKILL.md")).one?
      assert_includes actions.map(&:type), :skip_allowlist
    end
  end

  def test_copy_strips_runtime_exclusions
    with_manager_sandbox do |root|
      write_skill(root, "alpha", files: {
        ".DS_Store" => "metadata",
        ".skillkit.json" => "{}",
        ".skillfish.json" => "{}",
        ".git/config" => "git",
        "keep.txt" => "keep"
      })
      config = Skills::Config.load(root)
      mirror = Skills::Mirror.new(catalog: Skills::Catalog.new(config), config: config)
      destination = root.join("copied")

      mirror.atomic_copy(root.join("functional/alpha"), destination)

      assert_path_exists destination.join("keep.txt")
      refute_path_exists destination.join(".DS_Store")
      refute_path_exists destination.join(".skillkit.json")
      refute_path_exists destination.join(".skillfish.json")
      refute_path_exists destination.join(".git")
    end
  end

  def test_apply_collects_failures_and_continues_independent_actions
    with_manager_sandbox do |root|
      config = Skills::Config.load(root)
      mirror = Skills::Mirror.new(catalog: Skills::Catalog.new(config), config: config)
      attempted = []
      mirror.define_singleton_method(:atomic_copy) do |source, target|
        attempted << target.basename.to_s
        raise Errno::EACCES, target.to_s if target.basename.to_s == "first"

        FileUtils.mkdir_p(target)
      end
      actions = %w[first second].map do |name|
        Skills::Action.new(:add, name, root, root.join("target", name), nil)
      end

      findings = mirror.apply(actions)

      assert_equal %w[first second], attempted
      assert_equal 1, findings.length
      assert_path_exists root.join("target/second")
    end
  end

  def test_backup_names_do_not_collide_across_targets
    with_manager_sandbox do |root|
      targets = %w[a b].map do |name|
        target = root.join("targets", name)
        FileUtils.mkdir_p(target.join("orphan"))
        File.write(target.join("orphan/source.txt"), name)
        Skills::Target.new(name, target)
      end
      config = Skills::Config.load(root)
      mirror = Skills::Mirror.new(catalog: Skills::Catalog.new(config), config: config)
      backups = root.join("backups")

      mirror.apply(mirror.plan([], targets: targets), backup_root: backups)

      backed_up = Dir.glob(backups.join("*/*/source.txt")).map { |path| File.read(path) }.sort
      assert_equal %w[a b], backed_up
    end
  end
end
