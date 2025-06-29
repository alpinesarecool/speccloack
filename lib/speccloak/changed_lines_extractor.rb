# frozen_string_literal: true

module Speccloak
  module ChangedLinesExtractor
    def self.parse(diff_output, changed_lines)
      diff_output.each_line do |line|
        next unless line.start_with?("@@")

        match = line.match(Speccloak::GitCommands::DIFF_HUNK_HEADER_REGEX)
        next unless match

        start_line = match[1].to_i
        line_count = match[2] ? match[2].delete(",").to_i : 1
        (start_line...(start_line + line_count)).each { |line_num| changed_lines << line_num }
      end
      changed_lines
    end
  end
end
