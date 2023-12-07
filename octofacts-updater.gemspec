# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "octofacts-updater"
  spec.version       = File.read(File.expand_path("./.version", File.dirname(__FILE__))).strip
  spec.authors       = ["GitHub, Inc.", "Kevin Paulisse", "Antonio Santos"]
  spec.email         = "opensource+octofacts@github.com"

  spec.summary       = "Scripts to update octofacts fixtures from recent Puppet runs"
  spec.description   = <<-EOS
Octofacts-updater is a series of scripts to construct the fact fixture files and index files consumed by octofacts.
EOS
  spec.homepage      = "https://github.com/github/octofacts"
  spec.license       = "MIT"
  spec.executables   = "octofacts-updater"
  spec.files         = [
    "bin/octofacts-updater",
    Dir.glob("lib/octofacts_updater/**/*.rb"),
    "lib/octofacts_updater.rb",
    ".version"
  ].flatten
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"
  spec.add_dependency "diffy", ">= 3.1.0"
  spec.add_dependency "octocatalog-diff", ">= 2.1.0"
  spec.add_dependency "octokit", ">= 4.2.0"
  spec.add_dependency "net-ssh", ">= 2.9"
end
