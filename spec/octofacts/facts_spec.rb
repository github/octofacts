# frozen_string_literal: true
require "spec_helper"

describe Octofacts::Facts do
  describe "#select" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar") }

    let(:subject) { described_class.new(backend: backend) }

    it "should pass through select method to backend" do
      result = subject.select(foo: "bar")
      expect(result).to be_a_kind_of(Octofacts::Facts)
      expect(result.facts).to eq({ foo: "bar" })
      expect(backend.select_called).to eq(true)
    end

    it "should raise OperationNotPermitted if called after facts were manipulated" do
      result = subject.replace(foo: "baz")
      expect(result.facts).to eq({ foo: "baz" })
      expect { result.select(foo: "bar") }.to raise_error(Octofacts::Errors::OperationNotPermitted)
    end
  end

  describe "#reject" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar") }

    let(:subject) { described_class.new(backend: backend) }

    it "should pass through reject method to backend" do
      result = subject.reject(foo: "bar")
      expect(result).to be_a_kind_of(Octofacts::Facts)
      expect(result.facts).to eq({foo: "bar"})
      expect(backend.reject_called).to eq(true)
    end

    it "should raise OperationNotPermitted if called after facts were manipulated" do
      result = subject.replace(foo: "baz")
      expect(result.facts).to eq({ foo: "baz" })
      expect { result.reject(foo: "bar") }.to raise_error(Octofacts::Errors::OperationNotPermitted)
    end
  end

  describe "#prefer" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar") }

    let(:subject) { described_class.new(backend: backend) }

    it "should pass through prefer method to backend" do
      result = subject.prefer(foo: "bar")
      expect(result).to be_a_kind_of(Octofacts::Facts)
      expect(result.facts).to eq({foo: "bar"})
      expect(backend.prefer_called).to eq(true)
    end

    it "should raise OperationNotPermitted if called after facts were manipulated" do
      result = subject.replace(foo: "baz")
      expect(result.facts).to eq({ foo: "baz" })
      expect { result.prefer(foo: "bar") }.to raise_error(Octofacts::Errors::OperationNotPermitted)
    end
  end

  describe "#to_hash" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }

    let(:subject) { described_class.new(backend: backend) }

    it "should return a de-symbolized (string values) hash" do
      expect(subject.to_hash).to eq({"foo"=>"bar", "baz"=>{"buzz"=>"fizz"}})
    end
  end

  describe "#method_missing" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }

    let(:subject) { described_class.new(backend: backend) }

    it "should raise NameError when the method does not exist" do
      expect { subject.call(:thismethoddoesnotexistanywhere) }.to raise_error(NameError)
    end
  end

  describe "#[]" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }
    let(:subject) { described_class.new(backend: backend) }

    it "should transparently get data from the backend with a symbol key" do
      expect(subject[:foo]).to eq("bar")
    end

    it "should transparently get data from the backend with a string key" do
      expect(subject["foo"]).to eq("bar")
    end
  end

  describe "#fetch" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }
    let(:subject) { described_class.new(backend: backend) }

    it "should transparently get data from the backend with a symbol key" do
      expect(subject.fetch(:foo, "hats")).to eq("bar")
      expect(subject.fetch(:foo)).to eq("bar")
    end

    it "should transparently get data from the backend with a string key" do
      expect(subject.fetch("foo", "hats")).to eq("bar")
      expect(subject.fetch("foo")).to eq("bar")
    end
  end

  describe "#[]=" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }
    let(:subject) { described_class.new(backend: backend) }

    it "should set new facts with a symbol key" do
      subject[:xyz] = "zyx"
      expect(subject).to be_a_kind_of(Octofacts::Facts)
      expect(subject[:xyz]).to eq("zyx")
      expect(subject["xyz"]).to eq("zyx")
    end

    it "should set new facts with a symbol key" do
      subject["xyz"] = "zyx"
      expect(subject).to be_a_kind_of(Octofacts::Facts)
      expect(subject["xyz"]).to eq("zyx")
      expect(subject[:xyz]).to eq("zyx")
    end

    it "does not interfere with manipulators" do
      subject[:xyz] = "zyx"
      expect(subject).to be_a_kind_of(Octofacts::Facts)
      subject.replace(xyz: "xyz")
      expect(subject).to be_a_kind_of(Octofacts::Facts)
      expect(subject[:xyz]).to eq("xyz")
      expect(backend.facts[:xyz]).to eq("xyz")
    end
  end

  describe "#respond_to?" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }
    let(:subject) { described_class.new(backend: backend) }

    it "should return true when the method is available in the class" do
      expect(subject.respond_to?(:select)).to be_truthy
    end

    it "should return true when the method matches a manipulator" do
      expect(subject.respond_to?(:fake)).to be_truthy
    end

    it "should return true when the method is available in Hash" do
      expect(subject.respond_to?(:merge)).to be_truthy
    end

    it "should return false otherwise" do
      expect(subject.respond_to?(:foobar)).to be_falsey
    end
  end

  describe "#replace" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar", baz: { buzz: "fizz" }) }

    let(:subject) { described_class.new(backend: backend) }

    it "should return a Octofacts::Facts object when .replace is called" do
      result = subject.replace(foo: "bar")
      expect(result).to be_a_kind_of(Octofacts::Facts)
    end

    it "should return a Octofacts::Facts object when .replace is called multiple times" do
      result = subject.replace(foo: "bar").replace(baz: "baz").replace(buzz: "buzz")
      expect(result).to be_a_kind_of(Octofacts::Facts)
    end

    it "can still be accessed as a hash" do
      subject.replace(foo: "bar")
      expect(subject[:foo]).to eq("bar")
    end
  end

  describe "#string_or_symbolized_key" do
    let(:backend) { Octofacts::Backends::Hash.new({}) }
    let(:subject) { described_class.new(backend: backend) }

    it "should return string key if string key exists" do
      allow(subject).to receive(:facts).and_return(:foo => "bar", "fizz" => "buzz")
      expect(subject.send(:string_or_symbolized_key, "fizz")).to eq("fizz")
      expect(subject.send(:string_or_symbolized_key, :fizz)).to eq("fizz")
    end

    it "should return symbol key if symbol key exists" do
      allow(subject).to receive(:facts).and_return(:foo => "bar", "fizz" => "buzz")
      expect(subject.send(:string_or_symbolized_key, "foo")).to eq(:foo)
      expect(subject.send(:string_or_symbolized_key, :foo)).to eq(:foo)
    end

    it "should return input key if neither exist" do
      allow(subject).to receive(:facts).and_return(:foo => "bar", "fizz" => "buzz")
      expect(subject.send(:string_or_symbolized_key, "baz")).to eq("baz")
      expect(subject.send(:string_or_symbolized_key, :baz)).to eq(:baz)
    end
  end
end
