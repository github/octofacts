require "rake"
require "rspec/core/rake_task"
require_relative "rake/gem"

namespace :octofacts do
  task :default => [ ":octofacts:spec:octofacts", ":octofacts:spec:octofacts_updater", ":octofacts:spec:octofacts_integration" ] do
  end
end

RSpec::Core::RakeTask.new(:"octofacts:spec:octofacts") do |t|
  t.pattern = File.join(File.dirname(__FILE__), "spec/octofacts/**/*_spec.rb")
  t.name = "octofacts"
  ENV["SPEC_NAME"] = "octofacts"
end

RSpec::Core::RakeTask.new(:"octofacts:spec:octofacts_updater") do |t|
  t.pattern = File.join(File.dirname(__FILE__), "spec/octofacts_updater/**/*_spec.rb")
  t.name = "octofacts-updater"
  ENV["SPEC_NAME"] = "octofacts_updater"
end

RSpec::Core::RakeTask.new(:"octofacts:spec:octofacts_integration") do |t|
  t.pattern = File.join(File.dirname(__FILE__), "spec/integration/**/*_spec.rb")
  t.name = "octofacts-integration"
  ENV.delete("SPEC_NAME")
end

task default: :"octofacts:default"
