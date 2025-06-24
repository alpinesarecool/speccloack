# rubocop:disable all
# frozen_string_literal: true

require "spec_helper"
require "tempfile"
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

  describe "#initialize" do
    it "uses the default cmd_runner and file_reader when not provided" do
      checker = described_class.new
      expect(checker.instance_variable_get(:@cmd_runner).call("echo hi")).to eq("hi\n")
      Tempfile.create("speccloak_test") do |file|
        file.write("abc")
        file.rewind
        expect(checker.instance_variable_get(:@file_reader).call(file.path)).to eq("abc")
      end
    end
    it "accepts custom exclude_patterns" do
      checker = described_class.new(exclude_patterns: ["foo.rb"])
      expect(checker.instance_variable_get(:@exclude_patterns)).to include(/foo.rb/)
    end

    it "uses the provided cmd_runner" do
      fake_runner = ->(cmd) { "fake output" }
      checker = described_class.new(cmd_runner: fake_runner)
      expect(checker.instance_variable_get(:@cmd_runner)).to eq(fake_runner)
    end

    it "uses the provided file_reader" do
      fake_reader = ->(path) { "fake file" }
      checker = described_class.new(file_reader: fake_reader)
      expect(checker.instance_variable_get(:@file_reader)).to eq(fake_reader)
    end
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

    context "when the coverage file is invalid JSON" do
      it "logs an error when the coverage file cannot be parsed" do
        bad_file_reader = ->(_) { "not valid json" }
        checker = described_class.new(
          cmd_runner: ->(_) { "" },
          file_reader: bad_file_reader
        )
        allow(checker).to receive(:find_coverage_file).and_return("fake.json")
        allow(checker).to receive(:find_changed_files).and_return(["foo.rb"])
        expect(checker).to receive(:log).with(/Error parsing coverage file:/)
        checker.send(:analyze_files, ["foo.rb"], "fake.json")
      end
    end

    context "when there are uncovered lines in a changed file" do
      it "logs uncovered lines and adds them to @uncovered_lines when there are uncovered lines" do
        # Simulate coverage data with line 2 uncovered (0)
        file_reader = lambda do |path|
          if path.include?(".resultset.json")
            {
              "RSpec" => {
                "coverage" => {
                  File.expand_path("changed.rb") => { "lines" => [1, 0, 1] }
                }
              }
            }.to_json
          else
            "line1\nline2\nline3\n"
          end
        end
        
        # Simulate that line 2 is changed (and uncovered)
        cmd_runner = lambda do |cmd|
          case cmd
          when /diff --name-only/
            "changed.rb\n"
          when /ls-files/
            ""
          when /diff -U0/
            "@@ -2,1 +2,1 @@\n+line2\n"
          else
            ""
          end
        end

        checker = described_class.new(
          base: "origin/main",
          format: "text",
          cmd_runner: cmd_runner,
          file_reader: file_reader
        )
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:readlines).with("changed.rb").and_return(["line1\n", "line2\n", "line3\n"])
        expect {
          begin
            checker.run
          rescue SystemExit
          end
        }.to output(/Uncovered lines:.*2/m).to_stdout
      
        # Optionally, check that @uncovered_lines is set
        expect(checker.instance_variable_get(:@uncovered_lines)).to include(
          hash_including(file: "changed.rb", lines: [2])
        )
      end
    end
  end
end
# rubocop:enable all
