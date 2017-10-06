require "spec_helper"

describe OctofactsUpdater::Service::LocalFile do
  describe "#facts" do
    let(:node) { "foo.example.net" }
    let(:custom_exception) { RuntimeError.new("custom exception for testing") }

    context "when localfile is not configured" do
      it "should raise ArgumentError when localfile is undefined" do
        config = {}
        expect{ described_class.facts(node, config) }.to raise_error(ArgumentError, /requires localfile section/)
      end

      it "should raise ArgumentError when localfile is not a hash" do
        config = {"localfile" => :do_it}
        expect{ described_class.facts(node, config) }.to raise_error(ArgumentError, /requires localfile section/)
      end
    end

    context "when localfile is configured" do
      let(:file_path) { File.expand_path("../../fixtures/facts", File.dirname(__FILE__)) }

      it "should raise error if the path is undefined" do
        config = { "localfile" => {} }
        expect{ described_class.facts(node, config) }.to raise_error(ArgumentError, /requires 'path' in the localfile section/)
      end

      it "should raise error if the path does not exist" do
        config = { "localfile" => { "path" => File.join(file_path, "missing.yaml") } }
        expect{ described_class.facts(node, config) }.to raise_error(Errno::ENOENT, /LocalFile cannot find a file at/)
      end

      it "should return the proper object from the parsed file" do
        config = { "localfile" => { "path" => File.join(file_path, "basic.yaml") } }
        result = described_class.facts(node, config)
        desired_result = YAML.safe_load(File.read(File.join(file_path, "basic.yaml")))
        expect(result).to eq(desired_result)
      end
    end
  end
end
