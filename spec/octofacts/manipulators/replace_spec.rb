# frozen_string_literal: true
require "spec_helper"
require "yaml"

describe Octofacts::Manipulators do
  before(:each) do
    fixture = File.join(Octofacts::Spec.fixture_root, "facts", "basic.yaml")
    @obj = Octofacts.from_file(fixture)
  end

  it "should contain the expected facts" do
    expect(@obj.facts[:fqdn]).to eq("somenode.example.net")
    expect(@obj.facts[:hostname]).to eq("somenode")
    expect(@obj.facts[:processor0]).to eq("Intel(R) Xeon(R) CPU E5-2686 v4 @ 2.30GHz")
    expect(@obj.facts[:os][:family]).to eq("Debian")
  end

  it "should do nothing when called with no arguments" do
    @obj.replace
    expect(@obj.facts[:fqdn]).to eq("somenode.example.net")
    expect(@obj.facts[:hostname]).to eq("somenode")
    expect(@obj.facts[:processor0]).to eq("Intel(R) Xeon(R) CPU E5-2686 v4 @ 2.30GHz")
    expect(@obj.facts[:os][:family]).to eq("Debian")
  end

  it "should set a simple stringified fact at the top level, addressed by symbol" do
    @obj.replace(operatingsystem: "OctoAwesome OS")
    expect(@obj.facts[:operatingsystem]).to eq("OctoAwesome OS")
  end

  it "should set a simple stringified fact at the top level, addressed by string" do
    @obj.replace(operatingsystem: "OctoAwesome OS")
    expect(@obj.facts[:operatingsystem]).to eq("OctoAwesome OS")
  end

  it "should set two facts at the same time" do
    @obj.replace(operatingsystem: "OctoAwesome OS", hostname: "octoawesome")
    expect(@obj.facts[:hostname]).to eq("octoawesome")
    expect(@obj.facts[:operatingsystem]).to eq("OctoAwesome OS")
  end

  it "should instantiate a fact that did not exist before" do
    @obj.replace(hats: "OctoAwesome OS", hostname: "octoawesome")
    expect(@obj.facts[:hostname]).to eq("octoawesome")
    expect(@obj.facts[:hats]).to eq("OctoAwesome OS")
  end

  it "should set a nested fact" do
    @obj.replace("ec2_metadata::placement::availability-zone" => "the-moon-1a")
    expect(@obj.facts[:ec2_metadata][:placement][:"availability-zone"]).to eq("the-moon-1a")
  end

  it "should be possible to chain replace operators" do
    @obj.replace(operatingsystem: "OctoAwesome OS").replace(hostname: "octoawesome")
    expect(@obj.facts[:hostname]).to eq("octoawesome")
    expect(@obj.facts[:operatingsystem]).to eq("OctoAwesome OS")
  end

  it "should accept a single argument lambda" do
    @obj.replace(operatingsystem: lambda { |value| value.upcase })
    expect(@obj.facts[:hostname]).to eq("somenode")
    expect(@obj.facts[:operatingsystem]).to eq("DEBIAN")
  end

  it "should accept a 3 argument lambda" do
    @obj.replace(operatingsystem: lambda { |fact_set, key, value| fact_set[:hostname] + value })
    expect(@obj.facts[:operatingsystem]).to eq("somenodeDebian")
  end
end
