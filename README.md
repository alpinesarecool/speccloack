# Speccloak
<p>
  <a href="https://rubygems.org/gems/speccloak"><img src="https://img.shields.io/gem/v/speccloak.svg" alt="Gem Version"></a>
  <a href="https://github.com/alpinesarecool/speccloak/actions/workflows/ci.yml"><img src="https://github.com/alpinesarecool/speccloak/actions/workflows/ci.yml/badge.svg?branch=main" alt="Build Status"></a>
  <a href="https://rubygems.org/gems/speccloak"><img src="https://img.shields.io/gem/dt/speccloak.svg" alt="Downloads"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

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
## Use Cases

- *Code reviewers can skip worrying about if this lengthy PR changes has all of its lines covered by the specs.**
- *Private methods are tested through the main method without stubbing them.**
- *Developers get instant feedback on whether their changes are adequately tested before merging.**
- *Teams can enforce branch coverage as a required CI check, preventing untested code from being merged.**
- *Legacy codebases can incrementally improve coverage by focusing only on changed lines, not the entire project.**
- *Helps maintain high code quality and confidence during refactoring or large-scale changes.**
- *Automates the tedious process of manually checking coverage reports for every pull request.**
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
### Basic command

```bash
speccloak
```

### With CLI options

```bash
speccloak --base origin/develop --format json --exclude []
```
## Using Speccloak in CI (GitHub Actions)

If you have added `speccloak` to your Gemfile:

```ruby
gem 'speccloak'
```

You can run Speccloak as part of your CI pipeline.  
Here’s an example GitHub Actions step:

```yaml
- name: Install dependencies
  run: bundle install --jobs 4 --retry 3

- name: Run Speccloak branch coverage check
  run: bundle exec speccloak
```

**Tip:**  
- Make sure you have simplecov gem and when you run the specs it generates the coverage
- Make sure your test suite runs before Speccloak so that coverage data is generated.
- You can add this step after your `bundle exec rspec` or test step.

**Example full workflow:**

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
      - name: Install dependencies
        run: bundle install
      - name: Run tests
        run: bundle exec rspec
      - name: Run Speccloak branch coverage check
        run: bundle exec speccloak
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
#### Sample output from github actions
![Screenshot 2025-06-24 235100](https://github.com/user-attachments/assets/f9a4bc5f-edbf-4668-899d-9538a92e3f70)

### When lines are uncovered

```
Uncovered lines by file:
app/services/payment_handler.rb:
  Line 42: call_external_api

Coverage check failed: Above lines are not covered by specs.
```
#### Sample output from github actions
![Screenshot 2025-06-24 235014](https://github.com/user-attachments/assets/0c1b1280-71db-4e11-ac84-049b95b78922)

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

