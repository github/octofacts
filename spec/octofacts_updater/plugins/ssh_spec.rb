require "spec_helper"

describe "sshfp_randomize plugin" do
  let(:plugin) { OctofactsUpdater::Plugin.plugins[:sshfp_randomize] }
  let(:value) { "SSHFP 1 1 0123456789abcdef0123456789abcdef01234567\nSSHFP 1 2 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" }
  let(:args) {{ "plugin" => "sshfp_randomize" }}

  it "should be defined" do
    expect(plugin).to be_a_kind_of(Proc)
  end

  it "should raise an error if the input is not a sshfp key" do
    fact = OctofactsUpdater::Fact.new("foo", "kittens123")
    expect(OctofactsUpdater::Plugin).to receive(:warn)
      .with("RuntimeError occurred executing sshfp_randomize on foo with value \"kittens123\"")
    expect do
      OctofactsUpdater::Plugin.execute(:sshfp_randomize, fact, args)
    end.to raise_error(/Unparseable pattern: kittens123/)
  end

  it "should randomize a sshfp key" do
    allow(OctofactsUpdater::Plugin).to receive(:randomize_long_string) { |arg| "random:#{arg}" }
    fact = OctofactsUpdater::Fact.new("foo", value)
    OctofactsUpdater::Plugin.execute(:sshfp_randomize, fact, args)
    expect(fact.value).to eq("SSHFP 1 1 random:0123456789abcdef0123456789abcdef01234567\nSSHFP 1 2 random:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
  end
end
