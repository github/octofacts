# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "octofacts"
  spec.version       = File.read(File.expand_path("./.version", File.dirname(__FILE__))).strip
  spec.authors       = ["GitHub, Inc.", "Kevin Paulisse", "Antonio Santos"]
  spec.email         = "opensource+octofacts@github.com"

  spec.summary       = "Run your rspec-puppet tests against fake hosts that present almost real facts"
  spec.description   = <<-EOS
Octofacts provides fact fixtures built from recently-updated Puppet facts to rspec-puppet tests.
EOS
  spec.homepage      = "https://github.com/github/octofacts"
  spec.license       = "MIT"

  spec.files         = [Dir.glob("lib/octofacts/**/*.rb"), "lib/octofacts.rb", ".version"].flatten
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"
end
