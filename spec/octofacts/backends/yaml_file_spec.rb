# frozen_string_literal: true
require "spec_helper"

describe Octofacts::Backends::YamlFile do
  let(:fixture_file) { File.join(Octofacts::Spec.fixture_root, "facts", "basic.yaml") }
  let(:subject) { described_class.new(fixture_file) }

  describe "initialization" do
    it "can't be called with no arguments" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "needs to be passed a file" do
      expect { described_class.new("/tmp/thisfiledoesnotexist.yml") }.to raise_error(Errno::ENOENT)
    end
  end

  describe "#facts" do
    it "will return a hash" do
      expect(subject.facts).to be_a(Hash)
    end

    it "will return the proper hash" do
      expect(subject.facts[:"ec2_network_interfaces_macs_0a:11:22:33:44:55_owner_id"]).to eq("987654321012")
    end
  end

  describe "#select" do
    it "will do nothing if the file matches the conditions with symbolized keys" do
      expect { subject.select(domain: "example.net") }.not_to raise_error
    end

    it "will do nothing if the file matches the conditions with string keys" do
      expect { subject.select("domain" => "example.net") }.not_to raise_error
    end

    it "will raise an error if the file can't match the conditions" do
      expect { subject.select("domain" => "wrongdomain.net") }.to raise_error(Octofacts::Errors::NoFactsError)
    end
  end

  describe "#reject" do
    it "will do nothing if the file can't match the conditions with symbolized keys" do
      expect { subject.reject(domain: "wrongdomain.net") }.not_to raise_error
    end

    it "will do nothing if the file can't match the conditions with string keys" do
      expect { subject.reject("domain" => "wrongdomain.net") }.not_to raise_error
    end

    it "will raise an error if the file matches the conditions" do
      expect { subject.reject("domain" => "example.net") }.to raise_error(Octofacts::Errors::NoFactsError)
    end
  end

  describe "#prefer" do
    it "is a noop in this backend" do
      expect { subject.prefer("domain" => "example.net") }.not_to raise_error
      expect { subject.prefer(domain: "example.net") }.not_to raise_error
      expect { subject.prefer("domain" => "wrongdomain.net") }.not_to raise_error
      expect { subject.prefer(domain: "wrongdomain.net") }.not_to raise_error
    end
  end
end
