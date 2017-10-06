require "spec_helper"

describe OctofactsUpdater::Fixture do
  describe "#make" do
    let(:hostname) { "HostName" }
    let(:config) {{ "enc" => { "path" => "/foo" }, "puppetdb" => { "url" => "https://puppetdb.example.com:8081" } }}
    let(:enc_return) {{ "parameters" => { "fizz" => "buzz" }, "classes" => ["class1", "class2"] }}
    let(:fact_hash_with_values) {{ "name" => hostname, "values" => { "foo" => "bar" } }}

    it "should instantiate and return a fixture object with the given facts" do
      expect(OctofactsUpdater::Service::ENC).to receive(:run_enc).with(hostname, config).and_return(enc_return)
      expect(OctofactsUpdater::Service::PuppetDB).to receive(:facts).with(hostname, config).and_return(fact_hash_with_values)
      subject = described_class.make(hostname, config)
      expect(subject).to be_a_kind_of(OctofactsUpdater::Fixture)
      expect(subject.to_yaml).to eq("---\nfizz: buzz\nfoo: bar\n")
    end
  end

  describe "#facts_from_configured_datasource" do
    let(:custom_exception) { RuntimeError.new("custom exception for testing") }

    context "with no fact sources configured" do
      it "should raise ArgumentError" do
        config = {}
        expect { described_class.facts_from_configured_datasource("foo.example.net", config) }.to raise_error(ArgumentError)
      end
    end

    context "with puppetdb configured but broken and SSH not configured" do
      it "should raise error from PuppetDB" do
        config = {"puppetdb" => {}}
        expect(OctofactsUpdater::Service::PuppetDB).to receive(:facts).and_raise(custom_exception)
        expect { described_class.facts_from_configured_datasource("foo.example.net", config) }.to raise_error(custom_exception)
      end
    end

    context "with puppetdb configured and working" do
      it "should return parsed data" do
        config = {"puppetdb" => {}}
        expect(OctofactsUpdater::Service::PuppetDB).to receive(:facts).and_return("values" => {"foo" => "bar"})
        expect(described_class.facts_from_configured_datasource("foo.example.net", config)).to eq("foo" => "bar")
      end
    end

    context "with puppetdb not configured and SSH configured and working" do
      it "should return parsed data" do
        config = {"ssh" => {}}
        expect(OctofactsUpdater::Service::SSH).to receive(:facts).and_return("values" => {"foo" => "bar"})
        expect(described_class.facts_from_configured_datasource("foo.example.net", config)).to eq("foo" => "bar")
      end
    end

    context "with puppetdb not configured and SSH configured and working with facter-like output" do
      it "should return parsed data" do
        config = {"ssh" => {}}
        expect(OctofactsUpdater::Service::SSH).to receive(:facts).and_return({"foo" => "bar"})
        expect(described_class.facts_from_configured_datasource("foo.example.net", config)).to eq("foo" => "bar")
      end
    end

    context "with puppetdb not configured and SSH configured but broken" do
      it "should raise error from SSH" do
        config = {"ssh" => {}}
        expect(OctofactsUpdater::Service::SSH).to receive(:facts).and_raise(custom_exception)
        expect { described_class.facts_from_configured_datasource("foo.example.net", config) }.to raise_error(custom_exception)
      end
    end

    context "with puppetdb broken and SSH broken" do
      it "should raise error from SSH" do
        config = {"puppetdb" => {}, "ssh" => {}}
        expect(OctofactsUpdater::Service::PuppetDB).to receive(:facts).and_raise(ArgumentError)
        expect(OctofactsUpdater::Service::SSH).to receive(:facts).and_raise(custom_exception)
        expect { described_class.facts_from_configured_datasource("foo.example.net", config) }.to raise_error(custom_exception)
      end
    end
  end

  describe "#load_file" do
    let(:fixture_path) { File.expand_path("../fixtures/facts", File.dirname(__FILE__)) }

    it "should raise an error if the file does not exist" do
      fixture_file = File.join(fixture_path, "non-existing.yaml")
      expect { described_class.load_file("foo", fixture_file) }.to raise_error(Errno::ENOENT)
    end

    it "should return the object based on the YAML parsed file" do
      fixture_file = File.join(fixture_path, "basic.yaml")
      result = described_class.load_file("foo", fixture_file)
      expect(result).to be_a_kind_of(described_class)
      expect(result.facts["bios_release_date"].value).to eq("02/16/2017")
    end
  end

  describe "#initialize" do
    let(:subject) { described_class.new("HostName", { "config" => "value" }, { "foo" => "bar" }) }

    it "should instantiate hostname" do
      expect(subject.instance_variable_get("@hostname")).to eq("HostName")
    end

    it "should instantiate config" do
      expect(subject.instance_variable_get("@config")).to eq({ "config" => "value" })
    end

    it "should instantiate facts" do
      facts = subject.instance_variable_get("@facts")
      expect(facts["foo"]).to be_a_kind_of(OctofactsUpdater::Fact)
      expect(facts["foo"].value).to eq("bar")
    end
  end

  describe "#execute_plugins!" do
    let(:default_facts) { { "foo" => "bar", "fizz" => "buzz" } }

    it "should return the object if the config has no fact modifications" do
      config = {}
      subject = described_class.new("HostName", config, default_facts)
      expect(subject.execute_plugins!).to be_a_kind_of(OctofactsUpdater::Fixture)
      expect(subject.facts["foo"].value).to eq("bar")
      expect(subject.facts["fizz"].value).to eq("buzz")
    end

    it "should apply plugins as requested by fact configuration" do
      config = { "facts" => { "test" => { "plugin" => "foo" } } }
      expect(OctofactsUpdater::Plugin).to receive(:execute).with("foo", OctofactsUpdater::Fact, { "plugin" => "foo" }, Hash)
      subject = described_class.new("HostName", config, default_facts)
      expect(subject.execute_plugins!).to be_a_kind_of(OctofactsUpdater::Fixture)
      expect(subject.facts["foo"].value).to eq("bar")
      expect(subject.facts["fizz"].value).to eq("buzz")
    end
  end

  describe "#fact_names" do
    it "should return the YAML key when regexp and fact are not specified" do
      subject = described_class.new("HostName", {}, { "foo" => "bar", "fizz" => "buzz", "baz" => 42 })
      expect(subject.send(:fact_names, "foo", { "plugin" => "delete" })).to eq(["foo"])
    end

    it "should return the fact name when the fact name is specified" do
      subject = described_class.new("HostName", {}, { "foo" => "bar", "fizz" => "buzz", "baz" => 42 })
      expect(subject.send(:fact_names, "foo", { "plugin" => "delete", "fact" => "baz" })).to eq(["baz"])
    end

    it "should return all facts matching the regexp when a regexp is specified" do
      subject = described_class.new("HostName", {}, { "foo" => "bar", "fizz" => "buzz", "baz" => 42 })
      expect(subject.send(:fact_names, "foo", { "plugin" => "delete", "regexp" => "^f" })).to eq(["foo", "fizz"])
      expect(subject.send(:fact_names, "foo", { "plugin" => "delete", "regexp" => "z$" })).to eq(["fizz", "baz"])
      expect(subject.send(:fact_names, "foo", { "plugin" => "delete", "regexp" => "asdf" })).to eq([])
    end
  end

  describe "#to_yaml" do
    let(:subject) { described_class.new("HostName", {}, { "foo" => "bar", "fizz" => "buzz" }) }

    it "should return YAML representation with sorted keys" do
      expect(subject.to_yaml).to eq("---\nfizz: buzz\nfoo: bar\n")
    end
  end

  describe "#write_file" do
    let(:fixture_path) { File.expand_path("../fixtures/facts", File.dirname(__FILE__)) }

    before(:each) do
      @tempdir = Dir.mktmpdir
    end

    after(:each) do
      FileUtils.remove_entry_secure(@tempdir) if File.directory?(@tempdir)
    end

    it "should write out the YAML file with the data" do
      fixture_file = File.join(fixture_path, "basic.yaml")
      outfile = File.join(@tempdir, "foo.yaml")

      obj = described_class.load_file("foo", fixture_file)
      obj.write_file(outfile)

      expect(File.file?(outfile)).to eq(true)
      expect(File.read(outfile)).to eq(File.read(fixture_file))
    end
  end
end
