# frozen_string_literal: true

require_relative "helpers"

module Speccloak
  # Reports branch coverage results in summary or JSON format.
  class CoverageReporter
    include Helpers

    def initialize(uncovered_lines, total_changed_lines, covered_changed_lines, format)
      @uncovered_lines = uncovered_lines
      @total_changed_lines = total_changed_lines
      @covered_changed_lines = covered_changed_lines
      @format = format
    end

    def report_results
      @format == "json" ? handle_json_report : handle_summary_report
    end

    private

    def handle_json_report
      print_json_report
    end

    def handle_summary_report
      print_summary
      if uncovered?
        print_uncovered_details
        coverage_status(:failure)
      else
        coverage_status(:success)
      end
    end

    def uncovered?
      @uncovered_lines.any?
    end

    def coverage_status(type)
      if type == :failure
        log("\n#{Colors::RED}Coverage check failed: Above lines are not covered by specs.#{Colors::RESET}")
        exit_with_status("", ExitCodes::FAILURE)
      else
        log("\n#{Colors::GREEN}Coverage check passed: All changed lines are covered by tests.#{Colors::RESET}")
        exit_with_status("", ExitCodes::SUCCESS)
      end
    end

    def print_json_report
      result = {
        total_changed_lines: @total_changed_lines,
        covered_changed_lines: @covered_changed_lines,
        coverage_percent: coverage_percent,
        uncovered_files: @uncovered_lines.map { |item| { file: item[:file], lines: item[:lines] } }
      }

      log(JSON.pretty_generate(result))
      coverage_status(uncovered? ? :failure : :success)
    end

    def print_summary
      log("\n\n")
      log("----------------------------------------")
      log("BRANCH COVERAGE REPORT SUMMARY")
      log("----------------------------------------")
      log("Total changed lines: #{@total_changed_lines}")
      log("Covered changed lines: #{@covered_changed_lines}")
      log("Coverage percentage: #{coverage_color}#{coverage_percent}%#{Colors::RESET}")
    end

    def coverage_percent
      @total_changed_lines.positive? ? (@covered_changed_lines.to_f / @total_changed_lines * 100).round(2) : 100
    end

    def coverage_color
      coverage_percent == 100 ? Colors::GREEN : Colors::RED
    end

    def print_uncovered_details
      log("\nUncovered lines by file:")
      @uncovered_lines.each { |item| print_file_uncovered_lines(item[:file], item[:lines]) }
    end

    def print_file_uncovered_lines(file, lines)
      log("#{Colors::YELLOW}#{file}#{Colors::RESET}:")
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
          log("#{Colors::RED}#{Colors::BOLD}Line #{line_num}#{Colors::RESET}: #{code}")
        else
          print_line_not_found(line_num)
        end
      end
    end

    def print_missing_file_lines(lines)
      lines.each { |line_num| log("#{Colors::RED}#{Colors::BOLD}Line #{line_num}#{Colors::RESET} not covered by tests") }
    end

    def print_line_not_found(line_num)
      log("  #{Colors::RED}#{Colors::BOLD}Line #{line_num}#{Colors::RESET}: (line not found in file)")
    end
  end
end
