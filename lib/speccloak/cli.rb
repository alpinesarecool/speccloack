# frozen_string_literal: true

require "optparse"
require "yaml"
require_relative "branch_coverage_checker"

module Speccloak
  class CLI
    def self.start(argv)
      config = default_config
      config.merge!(load_yaml_config) if File.exist?(".speccloak.yml")
      parse_options(argv, config)
      run_checker(config)
    end

    def self.default_config
      {
        base: "origin/main",
        format: "text",
        exclude: []
      }
    end

    def self.load_yaml_config
      YAML.load_file(".speccloak.yml").transform_keys(&:to_sym)
    end

    def self.parse_options(argv, config)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: speccloak [options]"
        define_options(opts, config)
      end
      parser.parse!(argv)
    end

    def self.define_options(opts, config)
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

    def self.run_checker(config)
      checker = BranchCoverageChecker.new(
        base: config[:base],
        format: config[:format],
        exclude_patterns: config[:exclude] || []
      )
      checker.run
    end

    private_class_method :default_config, :load_yaml_config, :parse_options, :run_checker, :define_options
  end
end
