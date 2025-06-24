# frozen_string_literal: true

require "spec_helper"
require "json"
require "speccloak/coverage_reporter"

RSpec.describe Speccloak::CoverageReporter do
  let(:log_output) { StringIO.new }
  let(:log_method) { ->(msg) { log_output.puts(msg) } }
  let(:exit_code) { [] }

  before do
    # Patch log and exit_with_status for testing
    allow_any_instance_of(described_class).to receive(:log) { |_, msg| log_method.call(msg) }
    allow_any_instance_of(described_class).to receive(:exit_with_status) { |_, _, code| exit_code << code }
  end

  let(:uncovered_lines) { [{ file: "foo.rb", lines: [2, 4] }] }
  let(:total_changed_lines) { 5 }
  let(:covered_changed_lines) { 3 }

  describe "#report_results" do
    context "when format is json and there are uncovered lines" do
      it "logs JSON output and exits with failure" do
        reporter = described_class.new(uncovered_lines, total_changed_lines, covered_changed_lines, "json")
        reporter.report_results
        output = log_output.string
        json_str = output[/\{.*\}/m]
        json = JSON.parse(json_str)
        expect(json["total_changed_lines"]).to eq(5)
        expect(json["covered_changed_lines"]).to eq(3)
        expect(json["coverage_percent"]).to eq(60.0)
        expect(json["uncovered_files"].first["file"]).to eq("foo.rb")
        expect(exit_code).to include(1)
      end
    end

    context "when format is json and all lines are covered" do
      it "logs JSON output and exits with success" do
        reporter = described_class.new([], 5, 5, "json")
        reporter.report_results
        output = log_output.string
        json_str = output[/\{.*\}/m]
        json = JSON.parse(json_str)
        expect(json["coverage_percent"]).to eq(100.0)
        expect(json["uncovered_files"]).to eq([])
        expect(exit_code).to include(0)
      end
    end

    context "when format is summary and there are uncovered lines" do
      it "prints summary, uncovered details, and exits with failure" do
        reporter = described_class.new(uncovered_lines, 5, 3, "text")
        allow(File).to receive(:exist?).and_return(false)
        reporter.report_results
        output = log_output.string
        expect(output).to include("BRANCH COVERAGE REPORT SUMMARY")
        expect(output).to include("Total changed lines: 5")
        expect(output).to include("Covered changed lines: 3")
        expect(output).to include("Coverage percentage: \e[31m60.0%\e[0m")
        expect(output).to include("Uncovered lines by file:")
        expect(output).to include("foo.rb")
        expect(output).to include("Line 2")
        expect(exit_code).to include(1)
      end
    end

    context "when format is summary and all lines are covered" do
      it "prints summary and exits with success" do
        reporter = described_class.new([], 5, 5, "text")
        reporter.report_results
        output = log_output.string
        expect(output).to include("BRANCH COVERAGE REPORT SUMMARY")
        expect(output).to include("Coverage percentage: \e[32m100.0%\e[0m")
        expect(output).to include("Coverage check passed")
        expect(exit_code).to include(0)
      end
    end

    context "when uncovered lines refer to an existing file" do
      it "prints code lines for uncovered lines" do
        reporter = described_class.new([{ file: "foo.rb", lines: [1] }], 1, 0, "text")
        allow(File).to receive(:exist?).with("foo.rb").and_return(true)
        allow(File).to receive(:readlines).with("foo.rb").and_return(["puts 'hi'\n"])
        reporter.report_results
        output = log_output.string
        expect(output).to include("Line 1")
        expect(output).to include("puts 'hi'")
      end

      it "prints a message when the uncovered line is not found in the file" do
        reporter = described_class.new([{ file: "foo.rb", lines: [10] }], 1, 0, "text")
        allow(File).to receive(:exist?).with("foo.rb").and_return(true)
        allow(File).to receive(:readlines).with("foo.rb").and_return(["puts 'hi'\n"]) # only 1 line

        reporter.report_results
        output = log_output.string
        expect(output).to include("Line 10")
        expect(output).to include("line not found in file")
      end
    end

    context "when uncovered lines refer to a missing file" do
      it "prints not covered by tests for each line" do
        reporter = described_class.new([{ file: "missing.rb", lines: [1, 2] }], 2, 0, "text")
        allow(File).to receive(:exist?).with("missing.rb").and_return(false)
        reporter.report_results
        output = log_output.string
        expect(output).to include("Line 1")
        expect(output).to include("not covered by tests")
      end
    end
  end
end
