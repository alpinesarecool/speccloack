# frozen_string_literal: true

module Speccloak
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
  end
end
