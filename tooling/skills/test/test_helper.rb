# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "pathname"
require "tmpdir"

class Minitest::Test
  def with_sandbox
    Dir.mktmpdir("skills-manager-test") do |directory|
      yield Pathname(directory)
    end
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
