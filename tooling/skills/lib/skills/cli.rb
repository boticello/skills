# frozen_string_literal: true

module Skills
  class CLI
    OPTION_SPECS = {
      apply: [nil, "Write changes (this command previews by default)"],
      global: [nil, "Operate on the global manifest (default when --project is absent)"],
      project: ["PATH", "Operate on the project at PATH"],
      json: [nil, "Emit machine-readable JSON"],
      strict: [nil, "Use the command's strict finding policy"],
      fix: [nil, "Propose fixes for safe findings"],
      from: ["PATH", "Source target root or skill directory"],
      category: ["NAME", "Canonical category for the gathered skill"],
      scope: ["SCOPE", "Overlap scope: global, project, or suite"],
      skill: ["NAME", "Fetch a single named skill from the repository"],
      all: [nil, "Fetch all skills recorded in SOURCES.toml"],
      list: [nil, "List repository contents without fetching"],
      ref: ["REF", "Git ref to update to (default: upstream HEAD)"]
    }.freeze

    COMMANDS = {
      "list" => {
        handler: :dispatch_list,
        summary: "Show every skill: home, global?, projects, suites, drift",
        args: "",
        options: %i[global project json],
        examples: ["skills list", "skills list --json"]
      },
      "enable" => {
        handler: :dispatch_enable,
        summary: "Add a skill to a manifest (default: global)",
        args: "<name>",
        options: %i[global project apply json],
        examples: ["skills enable alpha --global --apply"]
      },
      "disable" => {
        handler: :dispatch_disable,
        summary: "Remove a skill from a manifest",
        args: "<name>",
        options: %i[global project apply json],
        examples: ["skills disable alpha --global --apply"]
      },
      "deploy" => {
        handler: :dispatch_deploy,
        summary: "Mirror the resolved set to target dirs",
        args: "",
        options: %i[global project apply json],
        examples: ["skills deploy", "skills deploy --apply", "skills deploy --project ~/code/app --apply"]
      },
      "doctor" => {
        handler: :dispatch_doctor,
        summary: "Health-check all reference surfaces",
        args: "",
        options: %i[global project fix apply json],
        examples: ["skills doctor", "skills doctor --fix --apply"]
      },
      "gather" => {
        handler: :dispatch_gather,
        summary: "Adopt a stray skill from a target into canonical",
        args: "<name>",
        options: %i[from category apply json],
        examples: ["skills gather alpha", "skills gather alpha --from ~/.agents/skills --category tools --apply"]
      },
      "fetch" => {
        handler: :dispatch_fetch,
        summary: "Fetch a third-party skill into vendor/",
        args: "<owner/repo>",
        options: %i[skill list all apply json],
        examples: ["skills fetch owner/repo --list", "skills fetch owner/repo --skill name --apply", "skills fetch --all --apply"]
      },
      "update" => {
        handler: :dispatch_update,
        summary: "Follow upstream HEAD for a vendored skill",
        args: "<name>",
        options: %i[ref apply json],
        examples: ["skills update alpha --apply"]
      },
      "lint" => {
        handler: :dispatch_lint,
        summary: "Repository-wide quality check",
        args: "",
        options: %i[strict json],
        examples: ["skills lint", "skills lint --strict"]
      },
      "review" => {
        handler: :dispatch_review,
        summary: "Assess one canonical skill's writing quality",
        args: "<name>",
        options: %i[strict json],
        examples: ["skills review manage-skills", "skills review manage-skills --strict --json"],
        guidance: "meta/manage-skills/references/review.md"
      },
      "overlap" => {
        handler: :dispatch_overlap,
        summary: "Report skills with competing triggers",
        args: "[suite-name]",
        options: %i[scope project json],
        examples: ["skills overlap", "skills overlap --scope project --project ~/code/app", "skills overlap --scope suite build"]
      }
    }.freeze

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
      return top_level_help if command.nil? || command == "help" && @argv.empty?
      return command_help(@argv.shift) if command == "help"
      return top_level_help if %w[--help -h].include?(command)
      return command_help(command) if COMMANDS.key?(command) && @argv.intersect?(%w[--help -h])

      unless COMMANDS.key?(command)
        unknown_command(command)
        return 2
      end

      @command = command
      manager = Manager.new(root: @root)
      result = dispatch(manager, command)
      report(result)
      result.exit_code
    rescue OptionParser::ParseError => error
      report_error(error.message, 2)
      command_help(@command, io: @err) unless json_requested?
      2
    rescue ArgumentError => error
      report_error(error.message, 2)
    rescue StandardError => error
      report_error(error.message, 1)
    end

    private

    def dispatch(manager, command)
      options = { apply: false, json: false }
      parser = OptionParser.new
      COMMANDS.fetch(command).fetch(:options).each do |key|
        parser.on(*option_switch(key), OPTION_SPECS.fetch(key).fetch(1)) do |value|
          options[key] = value.nil? ? true : value
        end
      end
      parser.parse!(@argv)
      raise OptionParser::InvalidOption, "--global and --project are mutually exclusive" if options[:global] && options[:project]

      @json = options[:json]
      handler = COMMANDS.fetch(command).fetch(:handler)
      result = send(handler, manager, options)
      raise OptionParser::InvalidArgument, "unexpected arguments: #{@argv.join(" ")}" unless @argv.empty?

      result
    end
    def dispatch_list(manager, options)
      manager.list(project: options[:project])
    end

    def dispatch_enable(manager, options)
      dispatch_manifest_change(manager, options, :enable)
    end

    def dispatch_disable(manager, options)
      dispatch_manifest_change(manager, options, :disable)
    end

    def dispatch_manifest_change(manager, options, action)
      name = shift_argument!("skill name")
      manager.public_send(action, name, project: options[:project], apply: options[:apply])
    end

    def dispatch_deploy(manager, options)
      manager.deploy(project: options[:project], apply: options[:apply])
    end

    def dispatch_doctor(manager, options)
      manager.doctor(fix: options[:fix], apply: options[:apply], project: options[:project])
    end

    def dispatch_gather(manager, options)
      name = shift_argument!("skill name")
      manager.gather(name, from: options[:from], category: options[:category] || "personal", apply: options[:apply])
    end

    def dispatch_fetch(manager, options)
      if options[:all]
        raise OptionParser::InvalidOption, "fetch --all does not accept a repository" unless @argv.empty?

        manager.fetch_all(apply: options[:apply])
      else
        repository = shift_argument!("repository")
        manager.fetch(repository, skill: options[:skill], list: options[:list], apply: options[:apply])
      end
    end

    def dispatch_update(manager, options)
      name = shift_argument!("skill name")
      manager.update(name, ref: options[:ref], apply: options[:apply])
    end

    def dispatch_lint(manager, options)
      manager.lint(strict: options[:strict])
    end

    def dispatch_review(manager, options)
      name = shift_argument!("skill name")
      manager.review(name, strict: options[:strict])
    end

    def dispatch_overlap(manager, options)
      scope = options[:scope] || "global"
      suite = scope == "suite" ? @argv.shift : nil
      manager.overlap(scope: scope, project: options[:project], suite: suite)
    end

    def option_switch(key)
      argument = OPTION_SPECS.fetch(key).fetch(0)
      ["--#{key}#{argument ? " #{argument}" : ""}"]
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
    def json_requested?
      @json || @raw_argv.include?("--json")
    end

    def top_level_help(io: @out)
      width = COMMANDS.map { |name, spec| "#{name} #{spec.fetch(:args)}".strip.length }.max
      io.puts "Usage: skills <command> [options]"
      io.puts
      io.puts "Manage the canonical skills store and deploy to targets."
      io.puts
      io.puts "Commands:"
      COMMANDS.each do |name, spec|
        invocation = "#{name} #{spec.fetch(:args)}".strip
        tag = spec.fetch(:options).include?(:apply) ? "[preview]" : "[read-only]"
        io.puts format("  %-#{width}s  %s %s", invocation, spec.fetch(:summary), tag)
      end
      io.puts
      io.puts <<~CONVENTIONS
        Conventions:
          State-changing commands preview by default; pass --apply to write.
          Exit codes: 0 success, 1 errors and gating findings, 2 usage error.
          Deploy is a mirror: removals are backed up to ~/.local/state/skills-backups/.
      CONVENTIONS
      io.puts
      io.puts "Run `skills <command> --help` for command details."
      0
    end

    def command_help(command, io: @out)
      return unknown_command(command) unless COMMANDS.key?(command)

      spec = COMMANDS.fetch(command)
      io.puts "Usage: skills #{command} #{spec.fetch(:args)}".strip
      io.puts
      io.puts spec.fetch(:summary) + "."
      io.puts
      io.puts "Options:"
      spec.fetch(:options).each do |key|
        io.puts format("  %-18s %s", option_switch(key).first, OPTION_SPECS.fetch(key).fetch(1))
      end
      examples = spec.fetch(:examples)
      unless examples.empty?
        io.puts
        io.puts "Examples:"
        examples.each { |example| io.puts "  #{example}" }
      end
      guidance = spec[:guidance]
      if guidance
        io.puts
        io.puts Pathname(@root).join(guidance).read
      end
      0
    end

    def unknown_command(command)
      suggestion = COMMANDS.keys.min_by { |name| levenshtein(command, name) }
      hint = levenshtein(command, suggestion) <= 2 ? " (did you mean: #{suggestion}?)" : ""
      @err.puts "error: unknown command '#{command}'#{hint}"
      @err.puts
      top_level_help(io: @err)
      2
    end

    def levenshtein(a, b)
      previous = (0..b.length).to_a
      a.each_char.with_index(1) do |char, i|
        current = [i]
        b.each_char.with_index(1) do |other, j|
          cost = char == other ? 0 : 1
          current << [current[j - 1] + 1, previous[j] + 1, previous[j - 1] + cost].min
        end
        previous = current
      end
      previous[b.length]
    end
  end
end
