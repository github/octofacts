# Make sure the examples in the README document actually work. :-)

require "spec_helper"

describe "Examples from README.md" do
  let(:index_path) { File.join(Octofacts::Spec.fixture_root, "index.yaml") }
  let(:fixture_path) { File.join(Octofacts::Spec.fixture_root, "facts") }
  let(:subject) { described_class.new(index_path: index_path, fixture_path: fixture_path) }

  before(:each) do
    ENV["OCTOFACTS_INDEX_PATH"] = index_path
    ENV["OCTOFACTS_FIXTURE_PATH"] = fixture_path
  end

  after(:each)  do
    ENV["OCTOFACTS_INDEX_PATH"] = nil
    ENV["OCTOFACTS_FIXTURE_PATH"] = fixture_path
  end

  it "should grab a match from the index" do
    result = Octofacts.from_index(app: "ops", role: "consul", datacenter: "dc1")
    expect(result).to be_a_kind_of(Octofacts::Facts)
    expect(result.facts).to eq(
      {
        fqdn: "ops-consul-67890.dc1.example.com",
        datacenter: "dc1",
        app: "ops",
        env: "production",
        role: "consul",
        lsbdistcodename: "jessie",
        shorthost: "ops-consul-67890"
      }
    )
  end

  it "should grab a match from the index and replace" do
    result = Octofacts.from_index(app: "ops", role: "consul", datacenter: "dc1").replace(lsbdistcodename: "hats")
    expect(result).to be_a_kind_of(Octofacts::Facts)
    expect(result.facts).to eq(
      {
        fqdn: "ops-consul-67890.dc1.example.com",
        datacenter: "dc1",
        app: "ops",
        env: "production",
        role: "consul",
        lsbdistcodename: "hats",
        shorthost: "ops-consul-67890"
      }
    )
  end

  it "should work with plain old ruby calling `facts`" do
    f = Octofacts.from_index(app: "ops", role: "consul", datacenter: "dc1").facts
    f[:lsbdistcodename] = "hats"
    f.delete(:env)
    expect(f).to eq(
      {
        fqdn: "ops-consul-67890.dc1.example.com",
        datacenter: "dc1",
        app: "ops",
        role: "consul",
        lsbdistcodename: "hats",
        shorthost: "ops-consul-67890"
      }
    )
  end

  it "should work with plain old ruby without calling `facts`" do
    f = Octofacts.from_index(app: "ops", role: "consul", datacenter: "dc1")
    f[:lsbdistcodename] = "hats"
    f.delete(:env)
    expect(f).to be_a_kind_of(Octofacts::Facts)
    expect(f[:fqdn]).to eq("ops-consul-67890.dc1.example.com")
    expect(f[:datacenter]).to eq("dc1")
    expect(f[:app]).to eq("ops")
    expect(f[:role]).to eq("consul")
    expect(f[:lsbdistcodename]).to eq("hats")
  end
end
