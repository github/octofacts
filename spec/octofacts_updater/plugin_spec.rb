# frozen_string_literal: true
require "spec_helper"

describe OctofactsUpdater::Plugin do
  before(:each) do
    described_class.clear!(:test1)
  end

  after(:all) do
    described_class.clear!(:test1)
  end

  describe "#register" do
    let(:blk) { Proc.new { |_fact, _args| true } }

    it "should raise error upon attempting to register a plugin 2x" do
      expect do
        described_class.register(:test1, &blk)
      end.not_to raise_error

      expect do
        described_class.register(:test1, &blk)
      end.to raise_error(ArgumentError, /A plugin named test1 is already registered/)
    end

    it "should register a plugin such that it can be executed later" do
      described_class.register(:test1, &blk)
      expect(described_class.plugins.key?(:test1)).to eq(true)
      expect(described_class.plugins[:test1]).to eq(blk)
    end
  end

  describe "#execute" do
    it "should raise an error if the plugin method is not found" do
      dummy_fact = instance_double("OctofactsUpdater::Fact")
      expect { described_class.execute(:test1, dummy_fact, {}) }.to raise_error(NoMethodError, /A plugin named test1/)
    end

    it "should execute the plugin code if the plugin method is found" do
      fact = OctofactsUpdater::Fact.new("foo", "bar")
      blk = Proc.new { |fact, args| fact.value = args["value"] }
      described_class.register(:test1, &blk)
      described_class.execute(:test1, fact, { "plugin" => "test1", "value" => "value1" })
      expect(fact.value).to eq("value1")
      described_class.execute(:test1, fact, { "plugin" => "test1", "value" => "value2" })
      expect(fact.value).to eq("value2")
    end
  end

  describe "#randomize_long_string" do
    it "should return the expected result" do
      result = described_class.randomize_long_string("abcdefghijklmnop")
      expect(result).to eq("MKf99Vml4egcfIIM")
    end
  end
end
