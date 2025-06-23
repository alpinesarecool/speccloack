require "optparse"
require_relative "branch_coverage_checker"

module Speccloak
  class CLI
    def self.start(argv)
      options = {
        base: "origin/main",
        format: "text"
      }

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: speccloak [options]"

        opts.on("--base BRANCH", "Specify the base branch (default: origin/main)") do |branch|
          options[:base] = branch
        end

        opts.on("--format FORMAT", "Output format (text or json)") do |format|
          options[:format] = format
        end

        opts.on("-h", "--help", "Displays help") do
          puts opts
          exit
        end
      end

      parser.parse!(argv)

      checker = BranchCoverageChecker.new(base: options[:base], format: options[:format])
      checker.run
    end
  end
end
