# frozen_string_literal: true
if ENV["SPEC_NAME"]
  require "simplecov"
  require "simplecov-json"

  SimpleCov.root File.expand_path("..", File.dirname(__FILE__))
  SimpleCov.coverage_dir File.expand_path("../lib/#{ENV['SPEC_NAME']}/coverage", File.dirname(__FILE__))

  if ENV["JOB_NAME"]
    SimpleCov.formatters = [SimpleCov::Formatter::JSONFormatter]
  else
    SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter]
  end

  SimpleCov.start do
    add_filter "spec/"
    if ENV["SPEC_NAME"] == "octofacts"
      add_filter "lib/octofacts_updater.rb"
      add_filter "lib/octofacts_updater/"
    elsif ENV["SPEC_NAME"] == "octofacts_updater"
      add_filter "lib/octofacts.rb"
      add_filter "lib/octofacts/"
    end
  end

  require ENV["SPEC_NAME"]
  require_relative "octofacts/octofacts_spec_helper" if ENV["SPEC_NAME"] == "octofacts"
else
  require "octofacts"
  require_relative "octofacts/octofacts_spec_helper"
  require "octofacts_updater"
end

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

  config.before(:each) do
    ENV.delete("OCTOFACTS_INDEX_PATH")
    ENV.delete("OCTOFACTS_FIXTURE_PATH")
  end
end
