# frozen_string_literal: true

require_relative "lib/speccloak/version"

Gem::Specification.new do |spec|
  spec.name          = "speccloak"
  spec.version       = Speccloak::VERSION
  spec.authors       = ["nitinrajkumarparuchuri"]
  spec.email         = ["nitinrajkumar502@gmail.com"]

  spec.summary       = "Check coverage of changed lines in your branch with a single command."
  spec.description   = "Speccloak is a CLI tool that reports whether the changed lines in your Git branch " \
                        "are covered by specs, using SimpleCov’s JSON output."
  spec.homepage      = "https://github.com/alpinesarecool/speccloak"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # URLs
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alpinesarecool/speccloak"
  spec.metadata["changelog_uri"]   = "https://github.com/alpinesarecool/speccloak/blob/main/CHANGELOG.md"

  # Files included in gem
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      f == gemspec ||
        f.end_with?(".gem") ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir      = "exe"
  spec.executables = ["speccloak"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "optparse", "~> 0.1"
  spec.add_dependency "yaml", "~> 0.1"
end
