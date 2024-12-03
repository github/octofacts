# frozen_string_literal: true
source "https://rubygems.org"


gemspec name: "octofacts"
gemspec name: "octofacts-updater"

group :development do
  gem "parallel", "1.26.3"
  gem "pry", "~> 0.14"
  gem "rake", "~> 13.2"
  gem "rubocop-github", "~> 0.20.0"
  gem "simplecov", ">= 0.14.1"
  gem "simplecov-json", "~> 0.2"

  # Integration test
  # The puppet gem must be download and added to the vendor/cache manually
  # The puppet gem no longer identifies as belonging to the "ruby" platform so it won't be found on rubygems.org
  gem "puppet", "~> #{ENV['PUPPET_VERSION'] || '7.30.0'}"
  gem "rspec-puppet", "~> #{ENV['RSPEC_PUPPET_VERSION'] || '5.0.0'}"
end
