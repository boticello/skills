# frozen_string_literal: true

module Skills
  class CLI
    def self.run(argv, out: $stdout, err: $stderr, root: Dir.pwd)
      new(argv, out: out, err: err, root: root).run
    end

    def initialize(argv, out:, err:, root:)
      @argv = argv.dup
      @raw_argv = argv.dup
      @out = out
      @err = err
      @root = root
    end

    def run
      command = @argv.shift
      return usage if command.nil? || %w[help --help -h].include?(command)

      manager = Manager.new(root: @root)
      result = dispatch(manager, command)
      report(result)
      result.exit_code
    rescue OptionParser::ParseError => error
      report_error(error.message, 2)
    rescue ArgumentError => error
      report_error(error.message, 2)
    rescue StandardError => error
      report_error(error.message, 1)
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
      result = case command
               when "list" then manager.list(project: options[:project])
               when "deploy" then manager.deploy(project: options[:project], apply: options[:apply])
               when "enable", "disable"
                 name = shift_argument!("skill name")
                 manager.public_send(command, name, project: options[:project], apply: options[:apply])
               when "lint" then manager.lint(strict: options[:strict])
               when "doctor" then manager.doctor(fix: options[:fix], apply: options[:apply], project: options[:project])
               when "overlap"
                 scope = options[:scope] || "global"
                 suite = scope == "suite" ? @argv.shift : nil
                 manager.overlap(scope: scope, project: options[:project], suite: suite)
               when "gather"
                 name = shift_argument!("skill name")
                 manager.gather(name, from: options[:from], category: options[:category] || "personal", apply: options[:apply])
               when "fetch"
                 if options[:all]
                   raise OptionParser::InvalidOption, "fetch --all does not accept a repository" unless @argv.empty?

                   manager.fetch_all(apply: options[:apply])
                 else
                   repository = shift_argument!("repository")
                   manager.fetch(repository, skill: options[:skill], list: options[:list], apply: options[:apply])
                 end
               when "update"
                 name = shift_argument!("skill name")
                 manager.update(name, ref: options[:ref], apply: options[:apply])
               else
                 raise OptionParser::InvalidOption, "unknown command #{command}"
               end
      raise OptionParser::InvalidArgument, "unexpected arguments: #{@argv.join(" ")}" unless @argv.empty?

      result
    end

    def shift_argument!(name)
      @argv.shift || raise(OptionParser::MissingArgument, name)
    end

    def report(result)
      findings = result.findings.sort_by { |finding| [finding.severity == :error ? 0 : 1, finding.message] }
      if @json
        @out.puts JSON.generate(payload: json_value(result.payload), findings: findings.map { |finding| json_value(finding) })
        return
      end

      payload = result.payload || {}
      case payload[:kind]
      when :list then report_list(payload.fetch(:rows))
      when :deploy then Array(payload[:actions]).each { |action| @out.puts "#{action.type}: #{action.target}" }
      when :overlap then report_overlap(payload.fetch(:pairs))
      else report_summary(payload)
      end
      findings.each { |finding| @err.puts "#{finding.severity}: #{finding.message}" }
    end

    def report_list(rows)
      rows.each do |item|
        @out.puts [
          item[:name], item[:home], "global=#{item[:global]}",
          "projects=#{item[:projects].join(",")}", "suites=#{item[:suites].join(",")}",
          "drift=#{item[:drift].join(",")}"
        ].join("\t")
      end
    end

    def report_overlap(pairs)
      pairs.each do |pair|
        @out.puts "#{pair[:left]}\t#{pair[:right]}\tscore=#{format("%.3f", pair[:score])}\tshared=#{pair[:shared].join(",")}"
      end
    end

    def report_summary(payload)
      payload.each do |key, value|
        next if key == :kind

        @out.puts "#{key}: #{value.is_a?(Array) ? value.join(", ") : value}"
      end
    end

    def json_value(value)
      case value
      when Data then json_value(value.to_h)
      when Pathname then value.to_s
      when Symbol then value.to_s
      when Array then value.map { |item| json_value(item) }
      when Hash then value.to_h { |key, item| [key, json_value(item)] }
      else value
      end
    end

    def report_error(message, status)
      if @json || @raw_argv.include?("--json")
        @err.puts JSON.generate(error: message, exit_code: status)
      else
        @err.puts "error: #{message}"
      end
      status
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
