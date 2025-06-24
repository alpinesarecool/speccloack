# frozen_string_literal: true
require "json"
require_relative "changed_lines_extractor"
require_relative "file_coverage_analyzer"
require_relative "coverage_reporter"

module Speccloak
  module Colors
    RED    = "\e[31m".freeze
    GREEN  = "\e[32m".freeze
    YELLOW = "\e[33m".freeze
    RESET  = "\e[0m".freeze
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

  RSPEC_COVERAGE_KEY = "RSpec"
  UNIT_TESTS_COVERAGE_KEY = "unit_tests_0"

  RUBY_FILE_EXTENSION = ".rb"
  RESULTSET_FILE = ".resultset.json"

  DEFAULT_EXCLUDED_PATTERNS = [
    ".bundle/",
    "/lib/tasks",
    "db/schema.rb",
    "db/migrate",
    "config/routes.rb",
    "config/initializers",
    "db/seeds.rb",
    "spec"
  ].map { |pattern| /#{pattern}/ }

  def self.excluded_patterns
    if ENV["SPECLOAK_EXCLUDE"]
      ENV["SPECLOAK_EXCLUDE"].split(",").map { |pattern| /#{pattern.strip}/ }
    else
      DEFAULT_EXCLUDED_PATTERNS
    end
  end

  class BranchCoverageChecker
    def initialize(base: "origin/main", format: "text", exclude_patterns: [])
      @base = base
      @format = format
      @uncovered_lines = []
      @total_changed_lines = 0
      @covered_changed_lines = 0
      @exclude_patterns = exclude_patterns.map { |p| /#{p}/ }
      @untracked_files = []
    end

    def run
      coverage_file = find_coverage_file
      return exit_with_status("Coverage file not found.", ExitCodes::FAILURE) unless coverage_file
    
      changed_files = find_changed_files
      return exit_with_status("No Ruby files changed in this branch.", ExitCodes::SUCCESS) if changed_files.empty?
    
      analyze_files(changed_files, coverage_file)
      report_results
    end

    private

    def log(message)
      puts message
    end

    def exit_with_status(message, code = ExitCodes::SUCCESS)
      puts message
      exit(code)
    end

    def report_results
      CoverageReporter.new(
        @uncovered_lines,
        @total_changed_lines,
        @covered_changed_lines,
        @format
      ).report_results
    end

    def find_coverage_file
      coverage_file = File.join(build_coverage_dir, RESULTSET_FILE)
      return coverage_file if File.exist?(coverage_file)
    
      log("Coverage file not found: #{coverage_file}")
      nil
    end

    def build_coverage_dir
      if ENV["CI"]
        job = ENV["CIRCLE_JOB"] || ""
        node = ENV["CIRCLE_NODE_INDEX"] || ""
        File.join("tmp", "coverage", "#{job}_#{node}")
      else
        "coverage"
      end
    end

    def find_changed_files
      tracked_files = `git diff --name-only #{@base}`.split("\n")
      @untracked_files = `git ls-files --others --exclude-standard`.split("\n")
      changed_files = (tracked_files + @untracked_files).uniq
      
      # changed_files.reject! { |file| excluded_file?(file) }

      log("\n\nChanged files: \n#{changed_files.join("\n")}") unless changed_files.empty?
      log("\n")
      changed_files
    end

    def analyze_files(changed_files, coverage_file)
      coverage_data = JSON.parse(File.read(coverage_file))
      file_coverage = extract_file_coverage(coverage_data)

      changed_files.each do |file|
        analyze_file(file, file_coverage)
      end
    rescue JSON::ParserError => e
      log("Error parsing coverage file: #{e.message}")
    end

    def analyze_file(file, file_coverage)
      changed_lines = extract_changed_lines(file)
      return if changed_lines.empty?

      print_file_change_info(file, changed_lines)

      absolute_path = File.expand_path(file)
      if file_coverage[absolute_path]
        check_file_coverage(file, file_coverage[absolute_path], changed_lines)
      else
        log("No coverage data found for this file!")
      end
    end

    def extract_file_coverage(coverage_data)
      [RSPEC_COVERAGE_KEY, UNIT_TESTS_COVERAGE_KEY]
        .map { |key| coverage_data.dig(key, "coverage") }
        .find { |coverage| coverage } || {}
    end

    def excluded_file?(file)
      (@exclude_patterns + EXCLUDED_PATTERNS).any? { |pattern| file.match?(pattern) }
    end

    def print_file_change_info(file, changed_lines)
      log("\nFile: #{file}")
      log("Changed lines: #{changed_lines.join(", ")}")
    end

    def extract_changed_lines(file)
      return all_line_numbers(file) if untracked_file?(file)
      changed_lines_from_diff(file)
    end
    
    def all_line_numbers(file)
      File.foreach(file).with_index.map { |_, i| i + 1 }
    end
    
    def changed_lines_from_diff(file)
      changed_lines = []
      ChangedLinesExtractor.parse(
        `git diff -U0 #{@base} -- #{file}`,
        changed_lines
      )
      changed_lines
    end

    def untracked_file?(file)
      @untracked_files.include?(file)
    end
    
    def check_file_coverage(file, file_coverage_data, changed_lines)
      lines_data = file_coverage_data["lines"]
      analyzer = FileCoverageAnalyzer.new(lines_data, changed_lines)
      
      uncovered_lines = analyzer.uncovered_lines
      covered_count = analyzer.covered_count

      update_coverage_statistics(uncovered_lines.size, covered_count)
      record_file_coverage_results(file, uncovered_lines)
    end

    def update_coverage_statistics(uncovered_count, covered_count)
      @total_changed_lines += (uncovered_count + covered_count)
      @covered_changed_lines += covered_count
    end

    def record_file_coverage_results(file, uncovered_lines)
      return log("#{Colors::GREEN}All changed lines are covered!#{Colors::RESET}") if uncovered_lines.empty?
    
      @uncovered_lines << { file: file, lines: uncovered_lines }
      log("Uncovered lines: #{Colors::RED}#{uncovered_lines.join(", ")}#{Colors::RESET}")
    end
  end
end
