# frozen_string_literal: true
require "json"
require_relative "changed_lines_extractor"
require_relative "file_coverage_analyzer"
require_relative "coverage_reporter"

module Speccloak
  RED = "\e[31m"
  GREEN = "\e[32m"
  YELLOW = "\e[33m"
  RESET = "\e[0m"

  GIT_CHANGED_FILES_CMD = "git diff --name-only origin/main"
  GIT_CHANGED_LINES_CMD_PREFIX = "git diff -U0 origin/main -- "
  GIT_DIFF_HUNK_HEADER_PATTERN = /@@ -\d+,?\d* \+(\d+)(,\d+)?/

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
      exit(1) unless coverage_file

      changed_files = find_changed_files
      if changed_files.empty?
        puts "No Ruby files changed in this branch."
        exit(0)
      end

      analyze_files(changed_files, coverage_file)
      Speccloak::CoverageReporter.new(@uncovered_lines, @total_changed_lines, @covered_changed_lines, @format).report_results
    end

    private

    def find_coverage_file
      coverage_dir = build_coverage_dir
      coverage_file = "#{coverage_dir}/#{RESULTSET_FILE}"

      unless File.exist?(coverage_file)
        puts "Coverage file not found: #{coverage_file}"
        return nil
      end

      coverage_file
    end

    def build_coverage_dir
      if ENV["CI"]
        job = ENV["CIRCLE_JOB"] || ""
        node = ENV["CIRCLE_NODE_INDEX"] || ""
        "tmp/coverage/#{job}_#{node}"
      else
        "coverage"
      end
    end

    def find_changed_files
      tracked_files = `git diff --name-only #{@base}`.split("\n")
      @untracked_files = `git ls-files --others --exclude-standard`.split("\n")
      changed_files = (tracked_files + @untracked_files).uniq
      # changed_files.reject! { |file| excluded_file?(file) }

      puts "\n\nChanged files: \n#{changed_files.join("\n")}" unless changed_files.empty?
      puts "\n"
      changed_files
    end

    def analyze_files(changed_files, coverage_file)
      coverage_data = JSON.parse(File.read(coverage_file))
      file_coverage = extract_file_coverage(coverage_data)

      changed_files.each do |file|
        analyze_file(file, file_coverage)
      end
    end

    def extract_file_coverage(coverage_data)
      coverage_data.dig(RSPEC_COVERAGE_KEY, "coverage") ||
        coverage_data.dig(UNIT_TESTS_COVERAGE_KEY, "coverage") ||
        {}
    end

    def excluded_file?(file)
      (@exclude_patterns + EXCLUDED_PATTERNS).any? { |pattern| file.match?(pattern) }
    end

    def analyze_file(file, file_coverage)
      changed_lines = extract_changed_lines(file)
      return if changed_lines.empty?

      print_file_change_info(file, changed_lines)

      absolute_path = File.expand_path(file)
      if file_coverage[absolute_path]
        check_file_coverage(file, file_coverage[absolute_path], changed_lines)
      else
        puts "No coverage data found for this file!"
        @uncovered_lines << { file: file, lines: changed_lines }
      end
    end

    def print_file_change_info(file, changed_lines)
      puts "\nFile: #{file}"
      puts "Changed lines: #{changed_lines.join(", ")}"
    end

    # --- Extracted helpers below to reduce class length ---

    def extract_changed_lines(file)
      changed_lines = []
      if @untracked_files.include?(file)
        File.foreach(file).with_index { |_, i| changed_lines << (i + 1) }
      else
        diff_output = `git diff -U0 #{@base} -- #{file}`
        ChangedLinesExtractor.parse(diff_output, changed_lines)
      end

      changed_lines
    end

    def check_file_coverage(file, file_coverage_data, changed_lines)
      lines_data = file_coverage_data["lines"]
      analyzer = Speccloak::FileCoverageAnalyzer.new(lines_data, changed_lines)
      file_uncovered_lines = analyzer.uncovered_lines
      covered_count = analyzer.covered_count

      update_coverage_statistics(file_uncovered_lines.size, covered_count)
      record_file_coverage_results(file, file_uncovered_lines)
    end

    def update_coverage_statistics(uncovered_count, covered_count)
      @total_changed_lines += (uncovered_count + covered_count)
      @covered_changed_lines += covered_count
    end

    def record_file_coverage_results(file, uncovered_lines)
      if uncovered_lines.any?
        @uncovered_lines << { file: file, lines: uncovered_lines }
        puts "Uncovered lines: #{RED}#{uncovered_lines.join(", ")}#{RESET}"
      else
        puts "#{GREEN}All changed lines are covered!#{RESET}"
      end
    end
  end
end
