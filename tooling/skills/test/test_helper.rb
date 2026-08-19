# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "pathname"
require "open3"
require "tmpdir"

class Minitest::Test
  def with_sandbox
    Dir.mktmpdir("skills-manager-test") do |directory|
      yield Pathname(directory)
    end
  end

  def with_manager_sandbox
    Dir.mktmpdir("skills-manager") do |directory|
      root = Pathname(directory).join("repos/skills")
      FileUtils.mkdir_p(root.join("tooling/skills"))
      File.write(root.join("tooling/skills/skills.toml"), <<~TOML)
        ignore = ["tooling", "vendor", "target"]

        [[target]]
        name = "test"
        path = "#{root.join("target")}"
      TOML
      yield root
    end
  end

  def git(directory, *arguments)
    _stdout, stderr, status = Open3.capture3("git", "-C", directory.to_s, *arguments)
    assert_predicate status, :success?, "git #{arguments.join(" ")} failed: #{stderr}"
  end

  def write_skill(root, name, files: {})
    directory = root.join("functional", name)
    FileUtils.mkdir_p(directory)
    File.write(directory.join("SKILL.md"), "---\nname: #{name}\ndescription: #{name}\n---\n")
    files.each do |relative_path, content|
      destination = directory.join(relative_path)
      FileUtils.mkdir_p(destination.dirname)
      File.write(destination, content)
    end
  end
end
