require "spec_helper"

describe "delete plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:delete] }

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should set the value of a fact to nil" do
    fact = OctofactsUpdater::Fact.new("foo", "bar")
    args = { "plugin" => "delete" }
    OctofactsUpdater::Plugin.execute(:delete, fact, args)
    expect(fact.value).to be_nil
  end

  it "should remove a value within a structured fact" do
    value = { "one" => 1, "two" => 2 }
    fact = OctofactsUpdater::Fact.new("foo", value)
    args = { "plugin" => "delete", "structure" => "one" }
    OctofactsUpdater::Plugin.execute(:delete, fact, args)
    expect(fact.value).to eq({"two"=>2})
  end
end

describe "set plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:set] }

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should set the value of a fact" do
    value = { "one" => 1, "two" => 2 }
    fact = OctofactsUpdater::Fact.new("foo", value)
    args = { "plugin" => "set", "value" => "kittens" }
    OctofactsUpdater::Plugin.execute(:set, fact, args)
    expect(fact.value).to eq("kittens")
  end

  it "should set the value of a structured fact" do
    value = { "one" => 1, "two" => 2 }
    fact = OctofactsUpdater::Fact.new("foo", value)
    args = { "plugin" => "set", "value" => "kittens", "structure" => "one" }
    OctofactsUpdater::Plugin.execute(:set, fact, args)
    expect(fact.value).to eq({"one"=>"kittens", "two"=>2})
  end

  it "should add the value to a structured fact" do
    value = { "one" => 1, "two" => 2 }
    fact = OctofactsUpdater::Fact.new("foo", value)
    args = { "plugin" => "set", "value" => "kittens", "structure" => "three" }
    OctofactsUpdater::Plugin.execute(:set, fact, args)
    expect(fact.value).to eq({"one"=>1, "two"=>2, "three"=>"kittens"})
  end
end

describe "remove_from_delimited_string plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:remove_from_delimited_string] }
  let(:fact) { OctofactsUpdater::Fact.new("foo", "foo,bar,baz,fizz") }

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should raise ArgumentError if delimiter is not provided" do
    args = { "plugin" => "remove_from_delimited_string", "regexp" => ".*" }
    expect(OctofactsUpdater::Plugin).to receive(:warn)
      .with("ArgumentError occurred executing remove_from_delimited_string on foo with value \"foo,bar,baz,fizz\"")
    expect do
      OctofactsUpdater::Plugin.execute(:remove_from_delimited_string, fact, args)
    end.to raise_error(ArgumentError, /remove_from_delimited_string requires a delimiter/)
  end

  it "should raise ArgumentError if regexp is not provided" do
    args = { "plugin" => "remove_from_delimited_string", "delimiter" => "," }
    expect(OctofactsUpdater::Plugin).to receive(:warn)
      .with("ArgumentError occurred executing remove_from_delimited_string on foo with value \"foo,bar,baz,fizz\"")
    expect do
      OctofactsUpdater::Plugin.execute(:remove_from_delimited_string, fact, args)
    end.to raise_error(ArgumentError, /remove_from_delimited_string requires a regexp/)
  end

  it "should return joined string with elements matching regexp removed" do
    args = { "plugin" => "remove_from_delimited_string", "delimiter" => ",", "regexp" => "^b" }
    OctofactsUpdater::Plugin.execute(:remove_from_delimited_string, fact, args)
    expect(fact.value).to eq("foo,fizz")
  end

  it "should be a no-op if no elements match the regexp" do
    args = { "plugin" => "remove_from_delimited_string", "delimiter" => ",", "regexp" => "does-not-match" }
    OctofactsUpdater::Plugin.execute(:remove_from_delimited_string, fact, args)
    expect(fact.value).to eq("foo,bar,baz,fizz")
  end
end

describe "noop plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:noop] }

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should do nothing at all" do
    fact = OctofactsUpdater::Fact.new("foo", "kittens")
    args = { "plugin" => "noop" }
    OctofactsUpdater::Plugin.execute(:noop, fact, args)
    expect(fact.value).to eq("kittens")
  end
end

describe "randomize_long_string plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:randomize_long_string] }
  let(:value) { "1234567890abcdef" }
  let(:args) {{ "plugin" => "randomize_long_string" }}

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should randomize a string" do
    allow(OctofactsUpdater::Plugin).to receive(:randomize_long_string) { |arg| "random:#{arg}" }
    fact = OctofactsUpdater::Fact.new("foo", value)
    OctofactsUpdater::Plugin.execute(:randomize_long_string, fact, args)
    expect(fact.value).to eq("random:#{value}")
  end
end
