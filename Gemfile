source "https://rubygems.org"

gemspec name: "octofacts"
gemspec name: "octofacts-updater"

group :development do
  gem "parallel", "= 1.12.0"
  gem "pry", "~> 0.14.2"
  gem "rake", "~> 12.3"
  gem "rubocop-github", "~> 0.5.0"
  gem "simplecov", ">= 0.22.0"
  gem "simplecov-json", "~> 0.2.3"

  # Integration test
  gem "rspec-puppet", "~> #{ENV['RSPEC_PUPPET_VERSION'] || '3.0.0'}"
  gem "puppet", "~> #{ENV['PUPPET_VERSION'] || '6.25.1'}"
end
