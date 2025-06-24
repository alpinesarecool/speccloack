# frozen_string_literal: true

require "spec_helper"
require "speccloak/file_finder"

RSpec.describe Speccloak::FileFinder do
  let(:cmd_runner) do
    lambda do |cmd|
      case cmd
      when /diff --name-only/
        "changed1.rb\nchanged2.rb\n"
      when /ls-files/
        "untracked1.rb\nuntracked2.rb\n"
      else
        ""
      end
    end
  end

  subject(:finder) { described_class.new(cmd_runner, "origin/main") }

  describe "#changed_files" do
    it "returns the union of tracked and untracked files" do
      files = finder.changed_files
      expect(files).to contain_exactly(
        "changed1.rb", "changed2.rb", "untracked1.rb", "untracked2.rb"
      )
    end

    # rubocop:disable all
    it "removes duplicates" do
      dup_cmd_runner = lambda do |cmd|
        case cmd
        when /diff --name-only/
          "file.rb\n"
        when /ls-files/
          "file.rb\n"
        else
          ""
        end
      end
      finder_with_dups = described_class.new(dup_cmd_runner, "origin/main")
      files = finder_with_dups.changed_files
      expect(files).to eq(["file.rb"])
    end
    # rubocop:disable all

    it "returns an empty array if no files are changed or untracked" do
      empty_cmd_runner = ->(_cmd) { "" }
      finder_empty = described_class.new(empty_cmd_runner, "origin/main")
      expect(finder_empty.changed_files).to eq([])
    end
  end
end
