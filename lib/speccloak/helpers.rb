module Speccloak
  module Helpers
    def log(message)
      puts message
    end

    def exit_with_status(message, code = ExitCodes::SUCCESS)
      log(message)
      exit(code)
    end
  end

  module Colors
    RED    = "\e[31m"
    GREEN  = "\e[32m"
    YELLOW = "\e[33m"
    RESET  = "\e[0m"
    BOLD   = "\e[1m"
  end

  module ExitCodes
    SUCCESS = 0
    FAILURE = 1
  end

  module GitCommands
    CHANGED_FILES_CMD      = "git diff --name-only origin/main"
    CHANGED_LINES_CMD_PREF = "git diff -U0 origin/main -- "
    DIFF_HUNK_HEADER_REGEX = /@@ -\d+,?\d* \+(\d+)(,\d+)?/
  end
end