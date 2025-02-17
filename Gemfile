# frozen_string_literal: true
source "https://rubygems.org"


gemspec name: "octofacts"
gemspec name: "octofacts-updater"

group :development do
  gem "parallel", "1.26.3"
  gem "pry", "~> 0.15"
  gem "rake", "~> 13.2"
  gem "rubocop-github", "~> 0.20.0"
  gem "simplecov", ">= 0.14.1"
  gem "simplecov-json", "~> 0.2"

  # Integration test
  gem "puppet", "~> #{ENV['PUPPET_VERSION'] || '7.30.0'}"
  gem "rspec-puppet", "~> #{ENV['RSPEC_PUPPET_VERSION'] || '3.0.0'}"
end
