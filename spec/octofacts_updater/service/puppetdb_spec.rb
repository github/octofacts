# frozen_string_literal: true

require "spec_helper"

require "octocatalog-diff"

describe OctofactsUpdater::Service::PuppetDB do
  before(:each) do
    ENV.delete("PUPPETDB_URL")
  end

  after(:each) do
    ENV.delete("PUPPETDB_URL")
  end

  describe "#facts" do
    it "should return facts from octocatalog-diff" do
      facts_double = instance_double(OctocatalogDiff::Facts)
      facts_answer = { "foo" => "bar" }
      expected_args = {node: "foo.bar.node", backend: :puppetdb, puppetdb_url: "https://puppetdb.fake:8443"}
      expect(described_class).to receive(:puppetdb_url).and_return("https://puppetdb.fake:8443")
      expect(OctocatalogDiff::Facts).to receive(:new).with(expected_args).and_return(facts_double)
      expect(facts_double).to receive(:facts).and_return(facts_answer)
      expect(described_class.facts("foo.bar.node", {})).to eq(facts_answer)
    end

    it "should raise an error if facts cannot be determined" do
      facts_double = instance_double(OctocatalogDiff::Facts)
      expected_args = {node: "foo.bar.node", backend: :puppetdb, puppetdb_url: "https://puppetdb.fake:8443"}
      expect(described_class).to receive(:puppetdb_url).and_return("https://puppetdb.fake:8443")
      expect(OctocatalogDiff::Facts).to receive(:new).with(expected_args).and_return(facts_double)
      expect(facts_double).to receive(:facts).and_return(nil)
      expect { described_class.facts("foo.bar.node", {}) }.to raise_error(OctocatalogDiff::Errors::FactSourceError)
    end
  end

  describe "#puppetdb_url" do
    let(:fake_url) { "https://puppetdb.fake:8443" }
    it "should return puppetdb_url from configuration" do
      expect(described_class.puppetdb_url("puppetdb" => { "url" => fake_url })).to eq(fake_url)
    end

    it "should return PUPPETDB_URL from environment" do
      ENV["PUPPETDB_URL"] = fake_url
      expect(described_class.puppetdb_url).to eq(fake_url)
    end

    it "should raise an error if puppetdb URL cannot be determined" do
      expect { described_class.puppetdb_url }.to raise_error(/PuppetDB URL not configured or set in environment/)
    end
  end
end
