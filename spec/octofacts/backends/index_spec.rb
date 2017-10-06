require "spec_helper"

describe Octofacts::Backends::Index do
  let(:index_path) { File.join(Octofacts::Spec.fixture_root, "index.yaml") }
  let(:fixture_path) { File.join(Octofacts::Spec.fixture_root, "facts") }
  let(:backend) { described_class.new(octofacts_index_path: index_path, octofacts_fixture_path: fixture_path) }
  let(:subject) { Octofacts::Facts.new(backend: backend) }

  before(:each) do
    ENV["OCTOFACTS_INDEX_PATH"] = index_path
    ENV["OCTOFACTS_FIXTURE_PATH"] = fixture_path
  end

  describe "initialization"  do
    it "can be called with no arguments" do
      expect { described_class.new }.not_to raise_error
    end

    it "raises an error if the env variable is not defined and not index path passed" do
      ENV.delete("OCTOFACTS_INDEX_PATH")
      expect { described_class.new }.to raise_error(ArgumentError, /not defined/)
    end

    it "raises an error if the env variable is not defined and not fixture path passed" do
      ENV.delete("OCTOFACTS_FIXTURE_PATH")
      expect { described_class.new }.to raise_error(ArgumentError, /not defined/)
    end

    it "raises an error if the index path does not exist" do
      expect { described_class.new(octofacts_index_path: "notafile") }.to raise_error(Errno::ENOENT, /not exist/)
    end

    it "raises an error if the fixture path does not exist" do
      expect { described_class.new(octofacts_fixture_path: "notadirectory") }.to raise_error(Errno::ENOENT, /not exist/)
    end

    it "can be passed an index file" do
      ENV["OCTOFACTS_INDEX_PATH"] = nil
      expect { described_class.new(octofacts_index_path: index_path) }.not_to raise_error
    end

    it "can be passed a fixture path" do
      ENV["OCTOFACTS_FIXTURE_PATH"] = nil
      expect { described_class.new(octofacts_index_path: index_path, octofacts_fixture_path: fixture_path) }.not_to raise_error
    end

    it "can handle select conditions in addition to the built-in options" do
      args = {
        octofacts_index_path: index_path,
        octofacts_fixture_path: fixture_path,
        octofacts_strict_index: true,
        datacenter: "dc2"
      }
      answer = {
        "fqdn" => "ops-consul-12345.dc2.example.com",
        "datacenter" => "dc2",
        "app" => "ops",
        "env" => "production",
        "role" => "consul",
        "lsbdistcodename" => "precise",
        "shorthost" => "ops-consul-12345"
      }
      obj = described_class.new(datacenter: "dc2")
      expect(obj.send(:nodes)).to eq(["ops-consul-12345.dc2.example.com"])
      expect(obj.facts).to eq(answer)
    end
  end

  describe "#facts" do
    it "returns a hash" do
      expect(subject.facts).to be_a(Hash)
    end

    it "returns the facts for the first node in the collection" do
      expect(subject.facts[:fqdn]).to eq("ops-consul-67890.dc1.example.com")
    end
  end

  describe "#select" do
    it "selects the nodes that meet the conditions" do
      expect(subject.select(datacenter: "dc2").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "selects the nodes that meet the conditions with string keys" do
      expect(subject.select("datacenter" => "dc2").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "raises an error if no node can't meet the conditions" do
      expect { subject.select(datacenter: "dc3") }.to raise_error(Octofacts::Errors::NoFactsError)
    end

    it "can be passed more than one condition" do
      expect(subject.select(env: "staging", role: "puppetserver").facts[:fqdn]).to eq("puppet-puppetserver-00decaf.dc1.example.com")
    end

    it "returns itself so that it can be chained" do
      expect(subject.select(datacenter: "dc2")).to be(subject)
    end

    it "indexes and then selects based on an unindexed stringified fact" do
      obj = subject.select(fqdn: "ops-consul-12345.dc2.example.com").select(app: "ops")
      expect(backend.send("nodes")).to eq(["ops-consul-12345.dc2.example.com"])
    end

    it "indexes and then selects based on an unindexed symbolized fact" do
      obj = subject.select(fqdn: "ops-consul-12345.dc2.example.com").select(app: "ops")
      expect(backend.send(:nodes)).to eq(["ops-consul-12345.dc2.example.com"])
    end
  end

  describe "#reject" do
    it "removes nodes that don't meet the conditions" do
      expect(subject.reject(datacenter: "dc1").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "removes nodes that don't meet the conditions with string keys" do
      expect(subject.reject("datacenter" => "dc1").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "does nothing if no node meets the conditions" do
      expect(subject.reject(datacenter: "dc3").facts[:fqdn]).to eq("ops-consul-67890.dc1.example.com")
    end

    it "can be passed more than one condition" do
      expect(subject.reject(app: "puppet", datacenter: "dc1").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "returns itself so that it can be chained" do
      expect(subject.reject(datacenter: "dc2")).to be(subject)
    end

    it "returns an error if we reject everything" do
      expect { subject.reject(datacenter: "dc1").reject(datacenter: "dc2") }.to raise_error(Octofacts::Errors::NoFactsError)
    end

    it "indexes and then rejects based on an unindexed stringified fact" do
      obj = subject.reject(fqdn: "ops-consul-12345.dc2.example.com").select(app: "ops")
      expect(backend.send("nodes")).to eq(["ops-consul-67890.dc1.example.com"])
    end

    it "indexes and then rejects based on an unindexed symbolized fact" do
      obj = subject.reject(fqdn: "ops-consul-12345.dc2.example.com").select(app: "ops")
      expect(backend.send(:nodes)).to eq(["ops-consul-67890.dc1.example.com"])
    end
  end

  describe "#prefer" do
    it "sorts the nodes correctly if the conditions are met" do
      expect(subject.prefer(datacenter: "dc2").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "sorts the nodes correctly if the conditions are met with string keys" do
      expect(subject.prefer("datacenter" => "dc2").facts[:fqdn]).to eq("ops-consul-12345.dc2.example.com")
    end

    it "does not do anything if the conditions are not met" do
      expect(subject.prefer(datacenter: "dc3").facts[:fqdn]).to eq("ops-consul-67890.dc1.example.com")
    end

    it "returns itself so that it can be chained" do
      expect(subject.prefer(datacenter: "dc2")).to be(subject)
    end

    it "indexes and then prefers based on an unindexed fact" do
      obj = subject.prefer(fqdn: "ops-consul-67890.dc1.example.com").select(app: "ops")
      expect(backend.send(:nodes)).to eq(["ops-consul-67890.dc1.example.com", "ops-consul-12345.dc2.example.com"])
    end
  end

  describe "#add_fact_to_index" do
    it "raises an error when an unindexed fact is used and strict_index is true" do
      backend2 = described_class.new(octofacts_index_path: index_path, octofacts_fixture_path: fixture_path, octofacts_strict_index: true)
      subject2 = Octofacts::Facts.new(backend: backend2)
      expect { subject2.prefer(fqdn: "ops-consul-67890.dc1.example.com") }.to raise_error(Octofacts::Errors::FactNotIndexed)
    end

    it "raises an error when an unindexed fact is used and OCTOFACTS_STRICT_INDEX is true" do
      begin
        ENV["OCTOFACTS_STRICT_INDEX"] = "true"
        backend2 = described_class.new(octofacts_index_path: index_path, octofacts_fixture_path: fixture_path)
        subject2 = Octofacts::Facts.new(backend: backend2)
        expect { subject2.prefer(fqdn: "ops-consul-67890.dc1.example.com") }.to raise_error(Octofacts::Errors::FactNotIndexed)
      ensure
        ENV.delete("OCTOFACTS_STRICT_INDEX")
      end
    end
  end
end
