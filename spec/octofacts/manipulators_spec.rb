# frozen_string_literal: true
require "spec_helper"

describe Octofacts::Manipulators do
  describe "#self.run" do
    let(:backend) { Octofacts::Backends::Hash.new(foo: "bar") }

    let(:facts_object) { Octofacts::Facts.new(backend: backend) }

    it "should return false if no manipulator exists" do
      result = described_class.run(facts_object, "no_such_manipulator")
      expect(result).to eq(false)
    end
  end
end
