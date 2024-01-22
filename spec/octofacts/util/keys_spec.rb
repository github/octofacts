# frozen_string_literal: true
describe Octofacts::Util::Keys do
  describe "#downcase_keys!" do
    let(:facts) do
      { "foo" => "foo-value", "Bar" => "bar-value", :baz => "baz-value", :buZZ => "buzz-value" }
    end

    it "should work" do
      f = facts
      result = described_class.downcase_keys!(f)
      expect(f).to eq({foo: "foo-value", baz: "baz-value", bar: "bar-value", buzz: "buzz-value"})
      expect(result).to eq({"foo": "foo-value", baz: "baz-value", "bar": "bar-value", buzz: "buzz-value"})
    end
  end

  describe "#symbolize_keys!" do
    let(:facts) do
      { "foo" => "foo-value", "Bar" => "bar-value", :baz => "baz-value", :buZZ => "buzz-value" }
    end

    it "should work" do
      f = facts
      result = described_class.symbolize_keys!(f)
      expect(f).to eq({foo: "foo-value", baz: "baz-value", Bar: "bar-value", buZZ: "buzz-value"})
      expect(result).to eq({foo: "foo-value", baz: "baz-value", Bar: "bar-value", buZZ: "buzz-value"})
    end
  end

  describe "#desymbolize_keys!" do
    let(:facts) do
      { "foo" => "foo-value", "Bar" => "bar-value", :baz => "baz-value", :buZZ => "buzz-value" }
    end

    it "should work" do
      f = facts
      result = described_class.desymbolize_keys!(f)
      expect(f).to eq({"foo"=>"foo-value", "Bar"=>"bar-value", "baz"=>"baz-value", "buZZ"=>"buzz-value"})
      expect(result).to eq({"foo"=>"foo-value", "Bar"=>"bar-value", "baz"=>"baz-value", "buZZ"=>"buzz-value"})
    end
  end
end
