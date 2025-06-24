require "optparse"
require "yaml"
require_relative "branch_coverage_checker"

module Speccloak
  class CLI
    def self.start(argv)
      config = {
        base: "origin/main",
        format: "text",
        exclude: []
      }

      if File.exist?(".speccloak.yml")
        yaml_config = YAML.load_file(".speccloak.yml")
        config.merge!(yaml_config.transform_keys(&:to_sym))
      end

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: speccloak [options]"

        opts.on("--base BRANCH", "Specify the base branch (default: origin/main)") do |branch|
          config[:base] = branch
        end

        opts.on("--format FORMAT", "Output format (text or json)") do |format|
          config[:format] = format
        end

        opts.on("-h", "--help", "Display help information") do
          puts opts
          exit
        end
      end

      parser.parse!(argv)

      checker = BranchCoverageChecker.new(
        base: config[:base],
        format: config[:format],
        exclude_patterns: config[:exclude] || []
      )

      checker.run
    end
  end
end
