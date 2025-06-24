require "spec_helper"
require "speccloak/file_coverage_analyzer"

RSpec.describe Speccloak::FileCoverageAnalyzer do
  describe "#uncovered_lines" do
    it "returns changed lines that are uncovered (zero)" do
      lines_data = [1, 0, nil, 0, 1]
      changed_lines = [1, 2, 3, 4, 5]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.uncovered_lines).to eq([2, 4])
    end

    it "ignores changed lines outside the coverage array" do
      lines_data = [1, 0]
      changed_lines = [1, 2, 3]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.uncovered_lines).to eq([2])
    end

    it "ignores nil entries in lines_data" do
      lines_data = [nil, 0, 1]
      changed_lines = [1, 2, 3]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.uncovered_lines).to eq([2])
    end
  end

  describe "#covered_count" do
    it "returns the count of changed lines that are covered (positive)" do
      lines_data = [1, 0, 2, nil, 1]
      changed_lines = [1, 2, 3, 4, 5]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.covered_count).to eq(3)
    end

    it "returns zero if no changed lines are covered" do
      lines_data = [0, 0, nil]
      changed_lines = [1, 2, 3]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.covered_count).to eq(0)
    end

    it "ignores changed lines outside the coverage array" do
      lines_data = [1, 0]
      changed_lines = [1, 2, 3]
      analyzer = described_class.new(lines_data, changed_lines)
      expect(analyzer.covered_count).to eq(1)
    end
  end
end