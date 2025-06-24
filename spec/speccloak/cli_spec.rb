# frozen_string_literal: true

require "spec_helper"
require "speccloak/cli"

RSpec.describe Speccloak::CLI do
  let(:argv) { [] }

  before do
    # Stub BranchCoverageChecker so we don't run the actual logic
    stub_const("Speccloak::BranchCoverageChecker", Class.new do
      attr_reader :args

      def initialize(args)
        @args = args
      end

      def run = @ran = true
      def ran? = @ran
    end)
  end

  it "uses default config when no options or config file are provided" do
    expect_any_instance_of(Speccloak::BranchCoverageChecker).to receive(:run)
    expect do
      Speccloak::CLI.start(argv)
    end.not_to raise_error
  end

  it "parses --base option" do
    expect(Speccloak::BranchCoverageChecker).to receive(:new).with(
      hash_including(base: "mybranch")
    ).and_call_original
    Speccloak::CLI.start(["--base", "mybranch"])
  end

  it "parses --format option" do
    expect(Speccloak::BranchCoverageChecker).to receive(:new).with(
      hash_including(format: "json")
    ).and_call_original
    Speccloak::CLI.start(["--format", "json"])
  end

  it "loads config from .speccloak.yml if present" do
    yml = { "base" => "develop", "format" => "json", "exclude" => ["foo.rb"] }
    allow(File).to receive(:exist?).with(".speccloak.yml").and_return(true)
    allow(YAML).to receive(:load_file).with(".speccloak.yml").and_return(yml)
    expect(Speccloak::BranchCoverageChecker).to receive(:new).with(
      hash_including(base: "develop", format: "json", exclude_patterns: ["foo.rb"])
    ).and_call_original
    Speccloak::CLI.start([])
  end

  it "shows help and exits with -h" do
    expect { Speccloak::CLI.start(["-h"]) }.to output(/Usage: speccloak/).to_stdout.and raise_error(SystemExit)
  end

  it "shows help and exits with --help" do
    expect { Speccloak::CLI.start(["--help"]) }.to output(/Usage: speccloak/).to_stdout.and raise_error(SystemExit)
  end
end
