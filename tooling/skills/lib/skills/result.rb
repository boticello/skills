# frozen_string_literal: true

module Skills
  Finding = Data.define(:severity, :message)

  Result = Data.define(:findings, :payload) do
    def exit_code
      findings.empty? ? 0 : 1
    end
  end
end
