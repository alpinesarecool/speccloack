module Speccloak
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
end