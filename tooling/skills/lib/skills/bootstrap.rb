# frozen_string_literal: true

require "bundler"

module Skills
  class Bootstrap
    def self.ensure_dependencies!(project_root:, argv:, err: $stderr, setup: nil, installer: nil, restart: nil)
      project_root = File.expand_path(project_root)
      ENV["BUNDLE_GEMFILE"] = File.join(project_root, "Gemfile")
      setup ||= -> { require "bundler/setup" }
      installer ||= lambda do
        system(Gem.ruby, "-S", "bundle", "install", "--quiet", chdir: project_root)
      end
      restart ||= -> { exec(Gem.ruby, File.join(project_root, "bin/skills"), *argv) }

      setup.call
      true
    rescue Bundler::GemNotFound, LoadError => error
      err.puts "skills: installing missing bundled dependencies (#{error.message})"
      raise "bundle install failed" unless installer.call

      restart.call
      true
    end
  end
end
