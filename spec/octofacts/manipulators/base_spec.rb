require "spec_helper"

describe Octofacts::Manipulators do
  describe "#delete" do
    it "Should delete a string key at the top level" do
      fact_set = { foo: "bar", fizz: "buzz" }
      described_class.delete(fact_set, "foo")
      expect(fact_set).to eq(fizz: "buzz")
    end

    it "Should set a symbolized key at the top level" do
      fact_set = { foo: "bar", fizz: "buzz" }
      described_class.delete(fact_set, :foo)
      expect(fact_set).to eq(fizz: "buzz")
    end

    it "Should delete an intermediate nested key" do
      fact_set = { foo: "bar", level1: { string2: "foo", level2: { level3: "level4" } } }
      described_class.delete(fact_set, "level1::level2")
      expect(fact_set).to eq({foo: "bar", level1: {string2: "foo"}})
    end

    it "Should delete a final nested key" do
      fact_set = { foo: "bar", level1: { string2: "foo", level2: { level3: "level4" } } }
      described_class.delete(fact_set, "level1::level2::level3")
      expect(fact_set).to eq({foo: "bar", level1: {string2: "foo", level2: {}}})
    end

    it "Should not delete anything if the key was not a match" do
      fact_set = { foo: "bar", level1: { string2: "foo", level2: { level3: "level4" } } }
      described_class.delete(fact_set, "hats")
      described_class.delete(fact_set, :hats)
      described_class.delete(fact_set, "level1::hats::level3")
      described_class.delete(fact_set, "level1::level2::level3::level4")
      expect(fact_set).to eq({foo: "bar", level1: {string2: "foo", level2: {level3: "level4"}}})
    end
  end

  describe "#exists?" do
    it "Should operate at the top level with a string key" do
      fact_set = { foo: "bar" }
      expect(described_class.exists?(fact_set, "foo")).to eq(true)
      expect(described_class.exists?(fact_set, "baz")).to eq(false)
    end

    it "Should operate at the top level with a symbolized key" do
      fact_set = { foo: "bar" }
      expect(described_class.exists?(fact_set, :foo)).to eq(true)
      expect(described_class.exists?(fact_set, :baz)).to eq(false)
    end

    it "Should dig into a hash and find a nested key" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.exists?(fact_set, "level1::level2::level3")).to eq(true)
    end

    it "Should return false if the entire structure does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.exists?(fact_set, "hats::hats::hats")).to eq(false)
    end

    it "Should return false if the partial structure does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.exists?(fact_set, "level1::hats::hats")).to eq(false)
    end

    it "Should return false if the final fact does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.exists?(fact_set, "level1::level2::hats")).to eq(false)
    end

    it "Should return false if it encounters a non-hash intermediate key" do
      fact_set = { foo: "bar", level1: { string2: "foo", level2: { level3: "level4" } } }
      expect(described_class.exists?(fact_set, "level1::string2::baz")).to eq(false)
      expect(described_class.exists?(fact_set, "level1::level2::level3::level4")).to eq(false)
    end
  end

  describe "#get" do
    it "Should operate at the top level with a string key" do
      fact_set = { foo: "bar" }
      expect(described_class.get(fact_set, "foo")).to eq("bar")
      expect(described_class.get(fact_set, "baz")).to eq(nil)
    end

    it "Should operate at the top level with a symbolized key" do
      fact_set = { foo: "bar" }
      expect(described_class.get(fact_set, :foo)).to eq("bar")
      expect(described_class.get(fact_set, :baz)).to eq(nil)
    end

    it "Should dig into a hash and find a nested key" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.get(fact_set, "level1::level2::level3")).to eq("level4")
    end

    it "Should return false if the entire structure does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.get(fact_set, "hats::hats::hats")).to eq(nil)
    end

    it "Should return false if the partial structure does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.get(fact_set, "level1::hats::hats")).to eq(nil)
    end

    it "Should return false if the final fact does not exist" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      expect(described_class.get(fact_set, "level1::level2::hats")).to eq(nil)
    end

    it "Should return false if it encounters a non-hash intermediate key" do
      fact_set = { foo: "bar", level1: { string2: "foo", level2: { level3: "level4" } } }
      expect(described_class.get(fact_set, "level1::string2::baz")).to eq(nil)
      expect(described_class.get(fact_set, "level1::level2::level3::level4")).to eq(nil)
    end
  end

  describe "#set" do
    it "Should set a string key at the top level" do
      fact_set = { foo: "bar" }
      described_class.set(fact_set, "fizz", "buzz")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:fizz]).to eq("buzz")
    end

    it "Should set a symbolized key at the top level" do
      fact_set = { foo: "bar" }
      described_class.set(fact_set, :fizz, "buzz")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:fizz]).to eq("buzz")
    end

    it "Should replace a nested key" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      described_class.set(fact_set, "level1::level2::level3", "new_value")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:level1]).to eq({ level2: { level3: "new_value" }})
    end

    it "Should auto-create a complete hash structure" do
      fact_set = { foo: "bar" }
      described_class.set(fact_set, "level1::level2::level3", "new_value")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:level1]).to eq({ level2: { level3: "new_value" }})
    end

    it "Should auto-create a partial hash structure" do
      fact_set = { foo: "bar", level1: {} }
      described_class.set(fact_set, "level1::level2::level3", "new_value")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:level1]).to eq({ level2: { level3: "new_value" }})
    end

    it "Should auto-replace parts of a hash structure" do
      fact_set = { foo: "bar", level1: "foo" }
      described_class.set(fact_set, "level1::level2::level3", "new_value")
      expect(fact_set[:foo]).to eq("bar")
      expect(fact_set[:level1]).to eq({ level2: { level3: "new_value" }})
    end

    it "Should accept a lambda as the value and apply it at the top level" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |fact_set, fact_name, value| value.upcase }
      described_class.set(fact_set, "foo", my_lambda)
      expect(fact_set[:foo]).to eq("BAR")
    end

    it "Should accept a lambda as the value and (attempt to) apply it an intermediate nested level" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |fact_set, fact_name, value| value.merge(my_lambda_ran: true) }
      described_class.set(fact_set, "level1::level2", my_lambda)
      expect(fact_set[:level1][:level2]).to eq({ level3: "level4", my_lambda_ran: true })
    end

    it "Should accept a lambda as the value and apply it a final nested level" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |fact_set, fact_name, value| value.upcase }
      described_class.set(fact_set, "level1::level2::level3", my_lambda)
      expect(fact_set[:level1][:level2][:level3]).to eq("LEVEL4")
    end

    it "Should accept a lambda for a brand new key" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |fact_set, fact_name, value| "Make me new" }
      described_class.set(fact_set, "baz", my_lambda)
      expect(fact_set[:baz]).to eq("Make me new")
    end

    it "Should delete a key if the result of the lambda is nil" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |fact_set, fact_name, value| nil }
      described_class.set(fact_set, "foo", my_lambda)
      expect(fact_set.key?(:foo)).to eq(false)
    end

    it "Should accept a single argument lambda" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |value| "Make me new" }
      described_class.set(fact_set, "baz", my_lambda)
      expect(fact_set[:baz]).to eq("Make me new")
    end

    it "Should error if a lambda with the wrong arguments is passed" do
      fact_set = { foo: "bar", level1: { level2: { level3: "level4" } } }
      my_lambda = lambda { |foo, value| "Make me new" }
      expect { described_class.set(fact_set, "baz", my_lambda) }.to raise_error(ArgumentError, /1 or 3 parameters, got 2/)
    end
  end
end
