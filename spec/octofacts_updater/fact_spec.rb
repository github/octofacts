# frozen_string_literal: true
require "spec_helper"

describe OctofactsUpdater::Fact do
  describe "#value" do
    it "should return value if structured value is not requested" do
      subject = described_class.new("foo", "bar")
      expect(subject.value).to eq("bar")
    end

    it "should return nil if structured value is requested for non-structured fact" do
      subject = described_class.new("foo", "bar")
      expect(subject.value("foo")).to be_nil
      expect(subject.value("baz")).to be_nil
    end

    it "should return nil if not all keys exist in the path to a value" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      expect(subject.value("hats::baz::fizz")).to be_nil
      expect(subject.value("bar::hats::fizz")).to be_nil
    end

    it "should return nil if the last key does not exist" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      expect(subject.value("bar::baz::hats")).to be_nil
      expect(subject.value("bar::baz::fizz::buzz")).to be_nil
    end

    it "should return the value from the structured fact" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      expect(subject.value("bar::baz::fizz")).to eq("buzz")
      expect(subject.value("bar::baz")).to eq("fizz" => "buzz")
    end
  end

  describe "#value=" do
    it "should set the overall fact value if structured value is not requested" do
      subject = described_class.new("foo", "bar")
      subject.value = "baz"
      expect(subject.value).to eq("baz")
    end
  end

  describe "#set_value" do
    it "should set the overall fact value if structured value is not requested" do
      subject = described_class.new("foo", "bar")
      subject.set_value("baz")
      expect(subject.value).to eq("baz")
    end

    it "should call a block if provided instead of a static value" do
      subject = described_class.new("foo", "bar")
      blk = Proc.new { |val| val.upcase }
      subject.set_value(blk)
      expect(subject.value).to eq("BAR")
    end

    it "should raise an error if structured value is specified for non-structured fact" do
      subject = described_class.new("foo", "bar")
      expect { subject.set_value("baz", "foo") }.to raise_error(ArgumentError, /Cannot set structured value at "foo"/)
      expect { subject.set_value("baz", "key") }.to raise_error(ArgumentError, /Cannot set structured value at "key"/)
      expect { subject.set_value("baz", "bar::baz") }.to raise_error(ArgumentError, /Cannot set structured value at "bar"/)
    end

    it "should raise an error if it encounters a non-structured value in the path" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      expect { subject.set_value("baz", "bar::baz::fizz::buzz") }.to raise_error(ArgumentError, /Cannot set structured value at "buzz"/)
    end

    it "should create all missing hashes in structure to set value" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value("baz", "bar::baz::hats::caps")
      expect(subject.value("bar::baz::hats::caps")).to eq("baz")
      expect(subject.value("bar::baz")).to eq({"fizz"=>"buzz", "hats"=>{"caps"=>"baz"}})
    end

    it "should not create missing hashes if new value is nil" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value(nil, "bar::baz::hats::caps")
      expect(subject.value("bar::baz::hats::caps")).to be_nil
      expect(subject.value("bar::baz")).to eq("fizz" => "buzz")
    end

    it "should delete the structured value if new value is nil (at end)" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value(nil, "bar::baz::fizz")
      expect(subject.value("bar::baz::fizz")).to be_nil
      expect(subject.value("bar::baz")).to eq({})
    end

    it "should delete the structured value if new value is nil (in middle)" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value(nil, "bar::baz")
      expect(subject.value("bar::baz::fizz")).to be_nil
      expect(subject.value("bar")).to eq({})
    end

    it "should set value to new value within the structure" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value("kittens", "bar::baz::fizz")
      expect(subject.value("bar::baz::fizz")).to eq("kittens")
    end

    it "should accept an array of strings when describing the structure" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value("kittens", %w(bar baz fizz))
      expect(subject.value("bar::baz::fizz")).to eq("kittens")
    end

    it "should handle a structure at the top level of a structured fact" do
      subject = described_class.new("foo", "bar" => "baz")
      subject.set_value("kittens", "bar")
      expect(subject.value).to eq({ "bar" => "kittens" })
      expect(subject.value("bar")).to eq("kittens")
    end

    it "should handle regular expressions" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value("kittens", ["bar", { "regexp" => "^ba" }, { "regexp" => "zz" }])
      expect(subject.value("bar::baz::fizz")).to eq("kittens")
    end

    it "should not auto-create keys based on regular expressions" do
      subject = described_class.new("foo", "bar" => { "baz" => { "fizz" => "buzz" } })
      subject.set_value("kittens", ["bar", { "regexp" => "^boo" }, { "regexp" => "zz" }])
      expect(subject.value).to eq("bar" => { "baz" => { "fizz" => "buzz" } })
    end

    it "should match multiple keys when using regular expressions" do
      subject = described_class.new("foo", { "bar" => "!bar", "baz" => "!baz", "fizz" => "!fizz" })
      subject.set_value("kittens", [{ "regexp" => "^ba" }])
      expect(subject.value).to eq({"bar"=>"kittens", "baz"=>"kittens", "fizz"=>"!fizz"})
    end

    it "should call a Proc when matching multiple keys" do
      blk = Proc.new { |val| val.upcase }
      subject = described_class.new("foo", { "bar" => "!bar", "baz" => "!baz", "fizz" => "!fizz" })
      subject.set_value(blk, [{ "regexp" => "^ba" }])
      expect(subject.value).to eq({"bar"=>"!BAR", "baz"=>"!BAZ", "fizz"=>"!fizz"})
    end

    it "should delete values from a Proc when matching multiple keys" do
      blk = Proc.new { |val| val == "!bar" ? val.upcase : nil }
      subject = described_class.new("foo", { "bar" => "!bar", "baz" => "!baz", "fizz" => "!fizz" })
      subject.set_value(blk, [{ "regexp" => "^ba" }])
      expect(subject.value).to eq({"bar"=>"!BAR", "fizz"=>"!fizz"})
    end

    it "should raise an error if a part is not a string or regexp" do
      subject = described_class.new("foo", { "bar" => "!bar", "baz" => "!baz", "fizz" => "!fizz" })
      expect { subject.set_value("kittens", [:foo]) }.to raise_error(ArgumentError, /Unable to interpret structure item: :foo/)
    end

    it "should raise an error if the structure cannot be interpreted" do
      subject = described_class.new("foo", { "bar" => "!bar", "baz" => "!baz", "fizz" => "!fizz" })
      expect { subject.set_value("kittens", :foo) }.to raise_error(ArgumentError, /Unable to interpret structure: :foo/)
    end
  end
end
