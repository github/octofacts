require "spec_helper"

describe Octofacts::Util::Config do
  before(:all) do
    RSpec.configure do |c|
      c.add_setting :fake_setting
      c.fake_setting = "kittens"
    end
    ENV["FAKE_SETTING"] = "hats"
    ENV["FAKE_SETTING_2"] = "cats"
  end

  after(:all) do
    RSpec.configure do |c|
      c.fake_setting = nil
    end
    ENV.delete("FAKE_SETTING")
    ENV.delete("FAKE_SETTING_2")
  end

  describe "#fetch" do
    it "should return a value from the hash" do
      h = { fake_setting: "chickens" }
      expect(described_class.fetch(:fake_setting, h, "dogs")).to eq("chickens")
    end

    it "should return a value from the rspec configuration" do
      expect(described_class.fetch(:fake_setting, {}, "dogs")).to eq("kittens")
    end

    it "should return a value from the environment" do
      expect(described_class.fetch(:fake_setting_2, {}, "dogs")).to eq("cats")
    end

    it "should return the default value" do
      expect(described_class.fetch(:fake_setting_3, {}, "dogs")).to eq("dogs")
    end
  end
end
