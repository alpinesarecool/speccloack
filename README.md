# Speccloak

[![CI](https://github.com/alpinesarecool/speccloak/actions/workflows/main.yml/badge.svg)](https://github.com/alpinesarecool/speccloak/actions)
[![Gem Version](https://badge.fury.io/rb/speccloak.svg)](https://badge.fury.io/rb/speccloak)
[![Coverage Status](https://coveralls.io/repos/github/alpinesarecool/speccloak/badge.svg?branch=master)](https://coveralls.io/github/alpinesarecool/speccloak?branch=master)

**Speccloak** is a lightweight CLI tool that checks if the lines you've changed in your Git branch are covered by your test suite. ...

**Speccloak** is a lightweight CLI tool that checks if the lines you've changed in your Git branch are covered by your test suite. It helps you prevent untested changes from creeping into the codebase — effortlessly.

---

## What It Does

* Compares your current branch with a base branch (e.g. `origin/main`)
* Analyzes which lines have changed
* Uses SimpleCov's `.resultset.json` to verify test coverage for those lines
* Highlights which changed lines are not covered
* Supports `.speccloak.yml` config file and CLI overrides
* Outputs results in `text` or `json`

---

##  Installation

### From RubyGems (after publishing)

```bash
gem install speccloak
```

### From local gem build

```bash
git clone https://github.com/alpinesarecool/speccloak.git
cd speccloak
gem build speccloak.gemspec
gem install ./speccloak-0.1.0.gem
```

---

## Configuration

Create a `.speccloak.yml` in your project root:

```yaml
base: origin/main         # The branch to diff against
format: text              # text or json
exclude:                  # Exclude these path from checking the coverage
  - db/migrate
  - spec/
  - config/initializers
```

You can override these via CLI options as well.

---

##  Usage

### Basic command

```bash
speccloak
```

### With CLI options

```bash
speccloak --base origin/develop --format json --exclude []
```

### Show help

```bash
speccloak --help
```

```
Usage: speccloak [options]
    --base BRANCH                Specify the base branch (default: origin/main)
    --format FORMAT              Output format (text or json)
    -h, --help                   Display help information
```

---

## Output

### When everything is covered

```
File: app/models/user.rb
Changed lines: 12, 13
All changed lines are covered!

BRANCH COVERAGE REPORT SUMMARY
----------------------------------------
Total changed lines: 2
Covered changed lines: 2
Coverage percentage: 100%
```

### When lines are uncovered

```
Uncovered lines by file:
app/services/payment_handler.rb:
  Line 42: call_external_api

Coverage check failed: Above lines are not covered by specs.
```

---

## Development

To run the CLI directly from source:

```bash
bundle exec exe/speccloak
```

---

##  Releasing

After bumping the version in `lib/speccloak/version.rb`:

```bash
gem build speccloak.gemspec
gem push speccloak-<version>.gem
```

---

##  License

MIT © [Nitin Rajkumar Paruchuri](https://github.com/alpinesarecool)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

##  Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alpinesarecool/speccloak. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the code of conduct.

##  License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Speccloak project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alpinesarecool/speccloak/blob/master/CODE_OF_CONDUCT.md).

