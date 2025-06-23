# frozen_string_literal: true
require "json"

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

  EXCLUDED_PATTERNS = [
    ".bundle/",
    "/lib/tasks",
    "db/schema.rb",
    "db/migrate",
    "config/routes.rb",
    "config/initializers",
    "db/seeds.rb",
    "spec"
  ].map { |pattern| /#{pattern}/ }

  class FileCoverageAnalyzer
    def initialize(lines_data, changed_lines)
      @lines_data = lines_data
      @changed_lines = changed_lines
    end

    def uncovered_lines
      @changed_lines.select do |line_num|
        line_num - 1 < @lines_data.size &&
          !@lines_data[line_num - 1].nil? &&
          @lines_data[line_num - 1].zero?
      end
    end

    def covered_count
      @changed_lines.count do |line_num|
        line_num - 1 < @lines_data.size &&
          !@lines_data[line_num - 1].nil? &&
          @lines_data[line_num - 1].positive?
      end
    end

    def hello
      if 1===1
        puts "Hello from FileCoverageAnalyzer"
      else
        puts "This will never be printed"
      end
    end
  end

  class CoverageReporter
    RED = "\e[31m"
    GREEN = "\e[32m"
    YELLOW = "\e[33m"
    BOLD = "\e[1m"
    RESET = "\e[0m"

    def initialize(uncovered_lines, total_changed_lines, covered_changed_lines, format)
      @uncovered_lines = uncovered_lines
      @total_changed_lines = total_changed_lines
      @covered_changed_lines = covered_changed_lines
      @format = format
    end

    def report_results
      if @format == "json"
        print_json_report
      else
        print_summary
        if @uncovered_lines.any?
          print_uncovered_details
          puts "\n#{RED}Coverage check failed: Above lines are not covered by specs.#{RESET}"
          exit(1)
        else
          puts "\n#{GREEN}Coverage check passed: All changed lines are covered by tests.#{RESET}"
          exit(0)
        end
      end
    end

    private

    def print_json_report
      result = {
        total_changed_lines: @total_changed_lines,
        covered_changed_lines: @covered_changed_lines,
        coverage_percent: (@total_changed_lines > 0 ? (@covered_changed_lines.to_f / @total_changed_lines * 100).round(2) : 0),
        uncovered_files: @uncovered_lines.map do |item|
          {
            file: item[:file],
            lines: item[:lines]
          }
        end
      }

      puts JSON.pretty_generate(result)

      if @uncovered_lines.any?
        exit(1)
      else
        exit(0)
      end
    end

    def print_summary
      print_summary_header
      print_summary_stats
      print_summary_coverage
    end

    def print_summary_header
      puts "\n\n"
      puts "----------------------------------------"
      puts "BRANCH COVERAGE REPORT SUMMARY"
      puts "----------------------------------------"
    end

    def print_summary_stats
      puts "Total changed lines: #{@total_changed_lines}"
      puts "Covered changed lines: #{@covered_changed_lines}"
    end

    def print_summary_coverage
      covered_percentage = if @total_changed_lines.positive?
                             (@covered_changed_lines.to_f / @total_changed_lines * 100).round(2)
                           else
                             0
                           end
      color = covered_percentage == 100 ? GREEN : RED
      puts "Coverage percentage: #{color}#{covered_percentage}%#{RESET}"
    end

    def print_uncovered_details
      puts "\nUncovered lines by file:"
      @uncovered_lines.each do |item|
        print_file_uncovered_lines(item[:file], item[:lines])
      end
    end

    def print_file_uncovered_lines(file, lines)
      puts "#{YELLOW}#{file}#{RESET}:"

      if File.exist?(file)
        print_existing_file_lines(file, lines)
      else
        print_missing_file_lines(lines)
      end
    end

    def print_existing_file_lines(file, lines)
      file_lines = File.readlines(file)

      lines.each do |line_num|
        if line_num <= file_lines.size
          code = file_lines[line_num - 1].chomp.strip
          puts "  #{RED}#{BOLD}Line #{line_num}#{RESET}: #{code}"
        else
          print_line_not_found(line_num)
        end
      end
    end

    def print_missing_file_lines(lines)
      lines.each do |line_num|
        puts "  #{RED}#{BOLD}Line #{line_num}#{RESET} not covered by tests"
      end
    end

    def print_line_not_found(line_num)
      puts "  #{RED}#{BOLD}Line #{line_num}#{RESET}: (line not found in file)"
    end
  end

  class BranchCoverageChecker
    def initialize(base: "origin/main", format: "text")
      @base = base
      @format = format
      @uncovered_lines = []
      @total_changed_lines = 0
      @covered_changed_lines = 0
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
      CoverageReporter.new(@uncovered_lines, @total_changed_lines, @covered_changed_lines, @format).report_results
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
      changed_files = `git diff --name-only #{@base}`.split("\n").select { |file| file.end_with?(RUBY_FILE_EXTENSION) }
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
      EXCLUDED_PATTERNS.any? { |pattern| file.match?(pattern) }
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
      diff_output = `git diff -U0 #{@base} -- #{file}`
      ChangedLinesExtractor.parse(diff_output, changed_lines)
      changed_lines
    end

    def check_file_coverage(file, file_coverage_data, changed_lines)
      lines_data = file_coverage_data["lines"]
      analyzer = FileCoverageAnalyzer.new(lines_data, changed_lines)
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

  module ChangedLinesExtractor
    def self.parse(diff_output, changed_lines)
      diff_output.each_line do |line|
        next unless line.start_with?("@@")

        match = line.match(GIT_DIFF_HUNK_HEADER_PATTERN)
        next unless match

        start_line = match[1].to_i
        line_count = match[2] ? match[2][1..].to_i : 1

        (start_line...(start_line + line_count)).each do |line_num|
          changed_lines << line_num
        end
      end
    end
  end
end
