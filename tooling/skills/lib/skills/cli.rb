# frozen_string_literal: true

module Skills
  class CLI
    def self.run(argv, out: $stdout, err: $stderr, root: Dir.pwd)
      new(argv, out: out, err: err, root: root).run
    end

    def initialize(argv, out:, err:, root:)
      @argv, @out, @err, @root = argv.dup, out, err, root
    end

    def run
      command = @argv.shift
      return usage if command.nil? || %w[help --help -h].include?(command)
      manager = Manager.new(root: @root)
      result = dispatch(manager, command)
      report(result)
      result.exit_code
    rescue OptionParser::ParseError, ArgumentError => error
      @err.puts "error: #{error.message}"
      2
    rescue StandardError => error
      @err.puts "error: #{error.message}"
      1
    end

    private

    def dispatch(manager, command)
      options = { apply: false, json: false }
      parser = OptionParser.new
      parser.on("--apply") { options[:apply] = true }
      parser.on("--global") { options[:global] = true }
      parser.on("--project PATH") { |value| options[:project] = value }
      parser.on("--json") { options[:json] = true }
      parser.on("--strict") { options[:strict] = true }
      parser.on("--fix") { options[:fix] = true }
      parser.on("--from PATH") { |value| options[:from] = value }
      parser.on("--category NAME") { |value| options[:category] = value }
      parser.on("--scope SCOPE") { |value| options[:scope] = value }
      parser.on("--skill NAME") { |value| options[:skill] = value }
      parser.on("--all") { options[:all] = true }
      parser.on("--list") { options[:list] = true }
      parser.on("--ref REF") { |value| options[:ref] = value }
      parser.parse!(@argv)
      raise OptionParser::InvalidOption, "--global and --project are mutually exclusive" if options[:global] && options[:project]
      @json = options[:json]
      case command
      when "list" then manager.list(project: options[:project])
      when "deploy" then manager.deploy(project: options[:project], apply: options[:apply])
      when "enable", "disable"
        name = @argv.shift || raise(OptionParser::MissingArgument, "skill name")
        manager.public_send(command, name, project: options[:project], apply: options[:apply])
      when "lint" then manager.lint(strict: options[:strict])
      when "doctor" then manager.doctor(fix: options[:fix], apply: options[:apply], project: options[:project])
      when "overlap" then manager.overlap(scope: options[:scope] || "global", project: options[:project], suite: @argv.shift)
      when "gather"
        name = @argv.shift || raise(OptionParser::MissingArgument, "skill name")
        manager.gather(name, from: options[:from] || raise(OptionParser::MissingArgument, "--from"), category: options[:category] || "personal", apply: options[:apply])
      when "fetch"
        return manager.fetch_all(apply: options[:apply]) if options[:all]
        repository = @argv.shift || raise(OptionParser::MissingArgument, "repository")
        manager.fetch(repository, skill: options[:skill], list: options[:list], apply: options[:apply])
      when "update"
        name = @argv.shift || raise(OptionParser::MissingArgument, "skill name")
        manager.update(name, ref: options[:ref], apply: options[:apply])
      else
        raise OptionParser::InvalidOption, "unknown command #{command}"
      end
    end

    def report(result)
      findings = result.findings.sort_by { |finding| finding.severity == :error ? 0 : 1 }
      if @json
        @out.puts JSON.generate(payload: result.payload, findings: findings.map(&:to_h))
      else
        actions = result.payload.is_a?(Hash) ? result.payload[:actions] : nil
        Array(actions).each { |action| @out.puts "#{action.type}: #{action.target}" }
        Array(result.payload).each do |item|
          @out.puts [
            item[:name], item[:home], "global=#{item[:global]}",
            "projects=#{item[:projects].join(",")}", "suites=#{item[:suites].join(",")}",
            "drift=#{item[:drift].join(",")}"
          ].join("\t")
        end if result.payload.is_a?(Array)
        if result.payload.is_a?(Hash) && actions.nil?
          result.payload.each { |key, value| @out.puts "#{key}: #{value.is_a?(Array) ? value.join(", ") : value}" }
        end
        findings.each { |finding| @err.puts "#{finding.severity}: #{finding.message}" }
      end
    end

    def usage
      @out.puts <<~USAGE
        Usage: skills <command> [options]

        Commands: list, enable, disable, deploy, doctor, gather, fetch,
                  update, lint, overlap
        State-changing commands preview by default; pass --apply to write.
      USAGE
      0
    end
  end
end
