# frozen_string_literal: true
require "spec_helper"

describe OctofactsUpdater::FactIndex do
  let(:fixture_path) { File.expand_path("../fixtures", File.dirname(__FILE__)) }

  let(:fixture1) do
    OpenStruct.new(
      hostname: "host1",
      facts: {
        "fizz" => OpenStruct.new(value: { "buzz" => "zip" }),
        "foo" => OpenStruct.new(value: "bar")
      }
    )
  end

  let(:fixture2) do
    OpenStruct.new(
      hostname: "host2",
      facts: {
        "foo" => OpenStruct.new(value: "bar")
      }
    )
  end

  let(:fixture3) do
    OpenStruct.new(
      hostname: "host3",
      facts: {
        "foo" => OpenStruct.new(value: "baz")
      }
    )
  end

  let(:fixture4) do
    OpenStruct.new(
      hostname: "host4",
      facts: {
        "fizz" => OpenStruct.new(value: { "buzz" => "baz" })
      }
    )
  end

  describe "#load_file" do
    it "should raise an error if the file does not exist" do
      fixture_file = File.join(fixture_path, "non-existing.yaml")
      expect { described_class.load_file(fixture_file) }.to raise_error(Errno::ENOENT)
    end

    it "should return the object based on the YAML parsed file" do
      fixture_file = File.join(fixture_path, "index.yaml")
      result = described_class.load_file(fixture_file)
      expect(result).to be_a_kind_of(described_class)
      expect(result.nodes).to eq(["ops-consul-67890.dc1.example.com", "puppet-puppetserver-12345.dc1.example.com", "puppet-puppetserver-00decaf.dc1.example.com", "ops-consul-12345.dc2.example.com"])
    end
  end

  describe "#add" do
    let(:subject) { described_class.new({}) }

    it "should update index when fact did not exist before" do
      subject.add("foo", [fixture1, fixture2, fixture3, fixture4])
      expect(subject.index_data).to eq({"foo"=>{"bar"=>["host1", "host2"], "baz"=>["host3"]}})
    end

    it "should update index when fact existed before but value did not" do
      subject.add("foo", [fixture1, fixture2])
      subject.add("foo", [fixture3, fixture4])
      expect(subject.index_data).to eq({"foo"=>{"bar"=>["host1", "host2"], "baz"=>["host3"]}})
    end

    it "should update index when fact existed and value existed" do
      subject.add("foo", [fixture1, fixture4])
      subject.add("foo", [fixture3, fixture2])
      expect(subject.index_data).to eq({"foo"=>{"bar"=>["host1", "host2"], "baz"=>["host3"]}})
    end

    it "should add a structured fact" do
      subject.add("fizz.buzz", [fixture1, fixture2, fixture3, fixture4])
      expect(subject.index_data).to eq({"fizz.buzz"=>{"zip"=>["host1"], "baz"=>["host4"]}})
    end
  end

  describe "#nodes" do
    let(:fixture_file) { File.join(fixture_path, "index-no-nodes.yaml") }
    let(:subject) { described_class.load_file(fixture_file) }

    context "in quick mode" do
      it "should blindly display the nodes from the fixture" do
        result = subject.nodes(true)
        expect(result).to eq(["broken.example.com"])
      end
    end

    context "not in quick mode" do
      it "should re-compute and sort the nodes from the fixture" do
        result = subject.nodes(false)
        expect(result).to eq(["ops-consul-12345.dc2.example.com", "ops-consul-67890.dc1.example.com", "puppet-puppetserver-00decaf.dc1.example.com", "puppet-puppetserver-12345.dc1.example.com"])
      end
    end
  end

  describe "#reindex" do
    let(:subject) { described_class.new({}) }
    let(:answer) do
      {
        "foo"=>{
          "bar"=>["host1", "host2"],
          "baz"=>["host3"]
        },
        "bar"=>{},
        "fizz.buzz"=>{
          "zip"=>["host1"],
          "baz"=>["host4"]
        },
        "_nodes"=>["host1", "host2", "host3", "host4"]
      }
    end

    it "should construct the index from the provided fixtures" do
      subject.reindex(["foo", "bar", "fizz.buzz"], [fixture1, fixture2, fixture3, fixture4])
      expect(subject.index_data).to eq(answer)
    end
  end

  describe "#set_top_level_nodes_fact" do
    let(:subject) { described_class.new({}) }

    it "should set host names from fixtures (sorted)" do
      subject.set_top_level_nodes_fact([fixture3, fixture1, fixture2, fixture4])
      expect(subject.index_data["_nodes"]).to eq(["host1", "host2", "host3", "host4"])
    end
  end

  describe "#to_yaml" do
    let(:subject) { described_class.new({ "foo" => "bar", "fizz" => "buzz" }) }

    it "should return YAML representation with sorted keys" do
      expect(subject.to_yaml).to eq("---\nfizz: buzz\nfoo: bar\n")
    end
  end

  describe "#write_file" do
    let(:fixture_path) { File.expand_path("../fixtures", File.dirname(__FILE__)) }
    let(:fixture_file) { File.join(fixture_path, "index.yaml") }
    let(:sorted_fixture_file) { File.join(fixture_path, "sorted-index.yaml") }

    before(:each) do
      @tempdir = Dir.mktmpdir
    end

    after(:each) do
      FileUtils.remove_entry_secure(@tempdir) if File.directory?(@tempdir)
    end

    context "when filename is supplied" do
      it "should write out the YAML file with the data" do
        outfile = File.join(@tempdir, "foo.yaml")

        obj = described_class.load_file(fixture_file)
        obj.write_file(outfile)

        expect(File.file?(outfile)).to eq(true)
        expect(File.read(outfile)).to eq(File.read(sorted_fixture_file))
      end
    end

    context "when filename is in the object" do
      it "should write out the YAML file with the data" do
        outfile = File.join(@tempdir, "foo.yaml")

        obj = described_class.load_file(fixture_file)
        obj.instance_variable_set("@filename", outfile)
        obj.write_file

        expect(File.file?(outfile)).to eq(true)
        expect(File.read(outfile)).to eq(File.read(sorted_fixture_file))
      end
    end

    context "when filename is not supplied" do
      it "should raise ArgumentError" do
        obj = described_class.new({})
        expect { obj.write_file }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#get_fact" do
    let(:subject) { described_class.allocate }
    let(:fixture) { OpenStruct.new(hostname: "foo1", facts: facts_hash) }

    context "key not in hash" do
      let(:facts_hash) { {} }

      it "should return nil" do
        expect(subject.send(:get_fact, fixture, "foo")).to be_nil
      end
    end

    context "simple value (not structured)" do
      let(:facts_hash) { { "foo" => OpenStruct.new(value: "bar") } }

      it "should return the correct value" do
        expect(subject.send(:get_fact, fixture, "foo")).to eq("bar")
      end
    end

    context "structured value 2 levels" do
      let(:facts_hash) { { "foo" => OpenStruct.new(value: { "level1" => "bar" }) } }

      it "should return the correct value" do
        expect(subject.send(:get_fact, fixture, "foo.level1")).to eq("bar")
      end

      it "should return nil when the structure is not present" do
        expect(subject.send(:get_fact, fixture, "foo.bar")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.missing")).to be_nil
      end
    end

    context "structured value 3 levels" do
      let(:facts_hash) { { "foo" => OpenStruct.new(value: { "level1" => { "level2" => "bar" }}) } }

      it "should return the correct value" do
        expect(subject.send(:get_fact, fixture, "foo.level1.level2")).to eq("bar")
      end

      it "should return nil when the structure is not present" do
        expect(subject.send(:get_fact, fixture, "foo.missing.level1")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.missing")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.bar")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.missing")).to be_nil
      end
    end

    context "structured value 4 levels" do
      let(:facts_hash) { { "foo" => OpenStruct.new(value: { "level1" => { "level2" => { "level3" => "bar" }}}) } }

      it "should return the correct value" do
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.level3")).to eq("bar")
      end

      it "should return nil when the structure is not present" do
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.missing")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.missing.level3")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.missing.level2.level3")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.level3.bar")).to be_nil
        expect(subject.send(:get_fact, fixture, "foo.level1.level2.level3.missing")).to be_nil
      end
    end
  end
end
