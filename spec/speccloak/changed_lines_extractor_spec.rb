# frozen_string_literal: true

require "spec_helper"
require "speccloak/changed_lines_extractor"

RSpec.describe Speccloak::ChangedLinesExtractor do
  let(:regex) { Speccloak::GitCommands::DIFF_HUNK_HEADER_REGEX }

  it "extracts a single changed line" do
    diff = "@@ -1 +2 @@\n+foo"
    changed = []
    described_class.parse(diff, changed)
    expect(changed).to eq([2])
  end

  it "extracts a range of changed lines" do
    diff = "@@ -1,2 +3,4 @@\n+foo\n+bar\n+baz\n+qux"
    changed = []
    described_class.parse(diff, changed)
    expect(changed).to eq([3, 4, 5, 6])
  end

  it "returns empty if no hunk header" do
    diff = "+foo\n+bar"
    changed = []
    described_class.parse(diff, changed)
    expect(changed).to eq([])
  end

  it "appends to an existing array" do
    diff = "@@ -1 +10 @@\n+foo"
    changed = [1, 2]
    described_class.parse(diff, changed)
    expect(changed).to eq([1, 2, 10])
  end

  it "handles multiple hunks" do
    diff = "@@ -1 +2 @@\n+foo\n@@ -5 +10,2 @@\n+bar\n+baz"
    changed = []
    described_class.parse(diff, changed)
    expect(changed).to eq([2, 10, 11])
  end
end
