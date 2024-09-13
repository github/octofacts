# frozen_string_literal: true
# spec_helper for rspec-puppet fixture

require_relative "../../../lib/octofacts"
require "rspec-puppet"

def puppet_root
  File.expand_path("..", File.dirname(__FILE__))
end

def repo_root
  File.expand_path("../../..", File.dirname(__FILE__))
end

RSpec.configure do |c|
  c.module_path = File.join(puppet_root, "modules")
  c.hiera_config = File.join(puppet_root, "hiera.yaml")
  # c.manifest_dir = File.join(puppet_root, "manifests")
  c.manifest = File.join(puppet_root, "manifests", "defaults.pp")
  c.add_setting :octofacts_fixture_path, default: File.join(repo_root, "spec", "fixtures", "facts")
  c.add_setting :octofacts_index_path, default: File.join(repo_root, "spec", "fixtures", "index.yaml")
end
