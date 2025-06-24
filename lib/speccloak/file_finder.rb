# frozen_string_literal: true

module Speccloak
  class FileFinder
    def initialize(cmd_runner, base)
      @cmd_runner = cmd_runner
      @base = base
    end

    def changed_files
      tracked = @cmd_runner.call("git diff --name-only #{@base}").split("\n")
      untracked = @cmd_runner.call("git ls-files --others --exclude-standard").split("\n")
      (tracked + untracked).uniq
    end
  end
end
