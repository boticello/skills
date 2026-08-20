# frozen_string_literal: true

module Skills
  Finding = Data.define(:severity, :message, :criterion, :span, :suggestion)
  class << Finding
    alias_method :build, :new

    def new(severity, message, criterion: nil, span: nil, suggestion: nil)
      build(severity, message, criterion, span, suggestion)
    end
  end

  Result = Data.define(:findings, :payload, :status)
  class << Result
    alias_method :build, :new

    def new(findings, payload, status: nil)
      build(findings, payload, status)
    end
  end

  Result.class_eval do
    def exit_code
      status.nil? ? (findings.empty? ? 0 : 1) : status
    end
  end
end
