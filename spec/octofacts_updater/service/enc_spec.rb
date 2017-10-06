require "spec_helper"

require "ostruct"

describe OctofactsUpdater::Service::ENC do
  let(:config) {{ "enc" => { "path" => "/tmp/foo.enc" }}}

  describe "#run_enc" do
    it "should raise ArgumentError if no configuration for the ENC is defined" do
      expect { described_class.run_enc("HostName", {}) }.to raise_error(ArgumentError, /The ENC configuration must be defined/)
    end

    it "should raise ArgumentError if configuration does not have a path" do
      expect { described_class.run_enc("HostName", { "enc" => {} }) }.to raise_error(ArgumentError, /The ENC path must be defined/)
    end

    it "should raise Errno::ENOENT if the script doesn't exist at the path" do
      allow(File).to receive(:"file?").and_call_original
      allow(File).to receive(:"file?").with("/tmp/foo.enc").and_return(false)
      expect { described_class.run_enc("HostName", config) }.to raise_error(Errno::ENOENT, /The ENC script could not be found/)
    end

    it "should raise RuntimeError if the exit status from the ENC is nonzero" do
      allow(File).to receive(:"file?").and_call_original
      allow(File).to receive(:"file?").with("/tmp/foo.enc").and_return(true)
      open3_response = ["", "Whoopsie", OpenStruct.new(exitstatus: 1)]
      allow(Open3).to receive(:capture3).with("/tmp/foo.enc HostName").and_return(open3_response)
      expect { described_class.run_enc("HostName", config) }.to raise_error(%r{Error executing "/tmp/foo.enc HostName"})
    end

    it "should return the parsed YAML output from the ENC" do
      allow(File).to receive(:"file?").and_call_original
      allow(File).to receive(:"file?").with("/tmp/foo.enc").and_return(true)
      yaml_out = { "parameters" => { "foo" => "bar" } }.to_yaml
      open3_response = [yaml_out, "", OpenStruct.new(exitstatus: 0)]
      allow(Open3).to receive(:capture3).with("/tmp/foo.enc HostName").and_return(open3_response)
      expect(described_class.run_enc("HostName", config)).to eq("parameters" => { "foo" => "bar" })
    end
  end
end
