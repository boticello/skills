# frozen_string_literal: true

require_relative "test_helper"
require "skills/bootstrap"
require "stringio"

class SkillsBootstrapTest < Minitest::Test
  def test_missing_dependencies_install_then_restart
    installed = false
    restarted = false
    err = StringIO.new

    result = Skills::Bootstrap.ensure_dependencies!(
      project_root: Pathname(__dir__).parent,
      argv: ["list"],
      err: err,
      setup: -> { raise LoadError, "missing toml-rb" },
      installer: -> { installed = true },
      restart: -> { restarted = true }
    )

    assert_equal true, result
    assert_equal true, installed
    assert_equal true, restarted
    assert_includes err.string, "installing missing bundled dependencies"
  end

  def test_failed_dependency_install_is_reported
    error = assert_raises(RuntimeError) do
      Skills::Bootstrap.ensure_dependencies!(
        project_root: Pathname(__dir__).parent,
        argv: [],
        err: StringIO.new,
        setup: -> { raise LoadError, "missing" },
        installer: -> { false },
        restart: -> { flunk "must not restart" }
      )
    end

    assert_equal "bundle install failed", error.message
  end
end
