# frozen_string_literal: true
require "spec_helper"
require "ipaddr"

describe "ipv4_anonymize plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:ipv4_anonymize] }
  let(:fact)   { OctofactsUpdater::Fact.new("ipv4", "192.168.42.42") }
  let(:structured_fact) do
    OctofactsUpdater::Fact.new("networking",
      {
        "ip" => "192.168.42.42",
        "interfaces" => {
          "eth0" => {
            "ip" => "192.168.42.42"
          }
        }
      }
    )
  end

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should raise an error if the subnet is not passed" do
    args = { "plugin" => "ipv4_anonymize" }
    expect(OctofactsUpdater::Plugin).to receive(:warn)
      .with("ArgumentError occurred executing ipv4_anonymize on ipv4 with value \"192.168.42.42\"")
    expect do
      OctofactsUpdater::Plugin.execute(:ipv4_anonymize, fact, args)
    end.to raise_error(ArgumentError, /ipv4_anonymize requires a subnet/)
  end

  it "should change the IP to a given subnet" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "192.168.1.0/24" }
    OctofactsUpdater::Plugin.execute(:ipv4_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("192.168.1.60")
  end

  it "should properly update a structured fact at the top level" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "192.168.1.0/24", "structure" => "ip" }
    OctofactsUpdater::Plugin.execute(:ipv4_anonymize, structured_fact, args, { "hostname" => "myhostname" })
    expect(structured_fact.value["ip"]).to eq("192.168.1.60")
  end

  it "should properly update a structured fact nested within" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "192.168.1.0/24", "structure" => "interfaces::eth0::ip" }
    OctofactsUpdater::Plugin.execute(:ipv4_anonymize, structured_fact, args, { "hostname" => "myhostname" })
    expect(structured_fact.value["interfaces"]["eth0"]["ip"]).to eq("192.168.1.60")
  end

  it "should be consistent" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "10.0.0.0/8" }
    original_fact = fact.dup
    OctofactsUpdater::Plugin.execute(:ipv4_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("10.67.98.60")
    fact = original_fact
    OctofactsUpdater::Plugin.execute(:ipv4_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("10.67.98.60")
  end
end

describe "ipv6_anonymize plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:ipv6_anonymize] }
  let(:fact)   { OctofactsUpdater::Fact.new("ipv6", "fd00::/8") }
  let(:structured_fact) do
    OctofactsUpdater::Fact.new("networking",
      {
        "ip6" => "fd00::/8",
        "interfaces" => {
          "eth0" => {
            "ip6" => "fd00::/8"
          }
        }
      }
    )
  end

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should raise an error if the subnet is not passed" do
    args = { "plugin" => "ipv6_anonymize" }
    expect(OctofactsUpdater::Plugin).to receive(:warn)
      .with("ArgumentError occurred executing ipv6_anonymize on ipv6 with value \"fd00::/8\"")
    expect do
      OctofactsUpdater::Plugin.execute(:ipv6_anonymize, fact, args)
    end.to raise_error(ArgumentError, /ipv6_anonymize requires a subnet/)
  end

  it "should change the IP to a given subnet" do
    args = { "plugin" => "ipv6_anonymize", "subnet" => "fd00::/8" }
    OctofactsUpdater::Plugin.execute(:ipv6_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("fdcd:baee:2c4d:ab66:c3d5:2929:786a:9364")
  end

  it "should properly update a structured fact at the top level" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "fd00::/8", "structure" => "ip6" }
    OctofactsUpdater::Plugin.execute(:ipv6_anonymize, structured_fact, args, { "hostname" => "myhostname" })
    expect(structured_fact.value(args["structure"])).to eq("fdcd:baee:2c4d:ab66:c3d5:2929:786a:9364")
  end

  it "should properly update a structured fact nested within" do
    args = { "plugin" => "ipv4_anonymize", "subnet" => "fd00::/8", "structure" => "interfaces::eth0::ip6" }
    OctofactsUpdater::Plugin.execute(:ipv6_anonymize, structured_fact, args, { "hostname" => "myhostname" })
    expect(structured_fact.value(args["structure"])).to eq("fdcd:baee:2c4d:ab66:c3d5:2929:786a:9364")
  end

  it "should be consistent" do
    args = { "plugin" => "ipv6_anonymize", "subnet" => "fd00::/8" }
    original_fact = fact.dup
    OctofactsUpdater::Plugin.execute(:ipv6_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("fdcd:baee:2c4d:ab66:c3d5:2929:786a:9364")
    fact = original_fact
    OctofactsUpdater::Plugin.execute(:ipv6_anonymize, fact, args, { "hostname" => "myhostname" })
    expect(fact.value).to eq("fdcd:baee:2c4d:ab66:c3d5:2929:786a:9364")
  end
end
