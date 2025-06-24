# rubocop:disable all
# frozen_string_literal: true

require "spec_helper"
require "speccloak/branch_coverage_checker"

RSpec.describe Speccloak::BranchCoverageChecker do
  let(:cmd_runner) do
    lambda do |cmd|
      case cmd
      when /diff --name-only/
        "changed.rb\n"
      when /ls-files/
        "untracked.rb\n"
      when /diff -U0/
        # Simulate a diff output for changed.rb with lines 1 and 2 changed
        "@@ -1,2 +1,2 @@\n+line1\n+line2\n"
      else
        ""
      end
    end
  end

  let(:file_reader) do
    lambda do |path|
      if path.include?(".resultset.json")
        {
          "RSpec" => {
            "coverage" => {
              File.expand_path("changed.rb") => { "lines" => [1, nil, 0, 1] },
              File.expand_path("untracked.rb") => { "lines" => [1, 1, 1] }
            }
          }
        }.to_json
      else
        "line1\nline2\nline3\n"
      end
    end
  end

  subject(:checker) do
    described_class.new(
      base: "origin/main",
      format: "text",
      cmd_runner: cmd_runner,
      file_reader: file_reader
    )
  end

  describe "#run" do
    context "when coverage file does not exist" do
      before { allow(File).to receive(:exist?).and_return(false) }

      it "exits with failure (status 1) and logs the error" do
        expect {
          begin
            checker.run
          rescue SystemExit => e
            expect(e.status).to eq(1)
          end
        }.to output(/Coverage file not found/).to_stdout
      end
    end

    context "when there are no changed files" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(cmd_runner).to receive(:call).with(/diff --name-only/).and_return("")
        allow(cmd_runner).to receive(:call).with(/ls-files/).and_return("")
      end

      it "exits with success (status 0) and logs the message" do
        expect {
          begin
            checker.run
          rescue SystemExit => e
            expect(e.status).to eq(0)
          end
        }.to output(/No Ruby files changed in this branch/).to_stdout
      end
    end

    context "when there are changed files and coverage" do
      before { allow(File).to receive(:exist?).and_return(true) }

      it "prints changed files and coverage results" do
        expect {
          begin
            checker.run
          rescue SystemExit
          end
        }.to output(/Changed files:.*changed.rb.*untracked.rb/m).to_stdout
      end
    end

    context "when there are changed lines in a tracked file" do
      before { allow(File).to receive(:exist?).and_return(true) }

      it "prints the changed lines for the file" do
        expect {
          begin
            checker.run
          rescue SystemExit
          end
        }.to output(/Changed lines: 1, 2/).to_stdout
      end
    end

    context "when there are changed lines in an untracked file" do
      before { allow(File).to receive(:exist?).and_return(true) }

      it "prints all line numbers as changed lines for the untracked file" do
        expect {
          begin
            checker.run
          rescue SystemExit
          end
        }.to output(/Changed lines: 1, 2/).to_stdout
      end
    end
  end
end
# rubocop:enable all
