# frozen_string_literal: true

require "spec_helper"

describe OctofactsUpdater::Service::Base do
  describe "#parse_yaml" do
    it "should convert first '--- (whatever)' to just '---'" do
      text = <<-EOF
--- !ruby/object:Puppet::Node::Facts
name: foo-bar.example.net
values:
  agent_specified_environment: production
EOF
      result = described_class.parse_yaml(text)
      expect(result).to eq({"agent_specified_environment"=>"production"})
    end

    it "should convert first '--- (whatever)' to just '---' after comments" do
      text = <<-EOF
# Facts for foo-bar.example.net
--- !ruby/object:Puppet::Node::Facts
name: foo-bar.example.net
values:
  agent_specified_environment: production
EOF
      result = described_class.parse_yaml(text)
      expect(result).to eq({"agent_specified_environment"=>"production"})
    end

    it "should convert first '--- (whatever)' to just '---' after blank lines" do
      text = <<-EOF


--- !ruby/object:Puppet::Node::Facts
name: foo-bar.example.net
values:
  agent_specified_environment: production
EOF
      result = described_class.parse_yaml(text)
      expect(result).to eq({"agent_specified_environment"=>"production"})
    end

    it "should work correctly when first non-comment line is not '---'" do
      text = <<-EOF
# Test 123

# Test 456
name: foo-bar.example.net
values:
  agent_specified_environment: production
EOF
      result = described_class.parse_yaml(text)
      expect(result).to eq({"agent_specified_environment"=>"production"})
    end

    it "should convert a plain formatted fact file" do
      text = <<-EOF
---
  agent_specified_environment: production
EOF
      result = described_class.parse_yaml(text)
      expect(result).to eq({"agent_specified_environment"=>"production"})
    end
  end
end
