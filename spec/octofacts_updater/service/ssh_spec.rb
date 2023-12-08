# frozen_string_literal: true
require "spec_helper"

describe OctofactsUpdater::Service::SSH do
  describe "#facts" do
    let(:node) { "foo.example.net" }
    let(:custom_exception) { RuntimeError.new("custom exception for testing") }

    context "when ssh is not configured" do
      it "should raise ArgumentError when ssh is undefined" do
        config = {}
        expect { described_class.facts(node, config) }.to raise_error(ArgumentError, /requires ssh section/)
      end

      it "should raise ArgumentError when ssh is not a hash" do
        config = {"ssh" => :do_it}
        expect { described_class.facts(node, config) }.to raise_error(ArgumentError, /requires ssh section/)
      end
    end

    context "when ssh is configured" do
      it "should raise error if no server is configured" do
        config = { "ssh" => {} }
        expect { described_class.facts(node, config) }.to raise_error(ArgumentError, /requires 'server' in the ssh section/)
      end

      context "when user is unspecified" do
        before(:each) do
          @user_save = ENV.delete("USER")
        end

        after(:each) do
          if @user_save
            ENV["USER"] = @user_save
          else
            ENV.delete("USER")
          end
        end

        it "should raise error if no user is configured" do
          config = { "ssh" => { "server" => "puppetserver.example.net" } }
          expect { described_class.facts(node, config) }.to raise_error(ArgumentError, /requires 'user' in the ssh section/)
        end

        it "should use USER from environment if no user is configured" do
          ENV["USER"] = "ssh-user-from-env"
          config = { "ssh" => { "server" => "puppetserver.example.net" } }
          expect(Net::SSH).to receive(:start).with("puppetserver.example.net", "ssh-user-from-env", {}).and_raise(custom_exception)
          expect { described_class.facts(node, config) }.to raise_error(custom_exception)
        end
      end

      it "should raise error if SSH call fails" do
        config = { "ssh" => { "server" => "puppetserver.example.net", "user" => "foo", "extra" => "bar" } }
        ssh = double
        ssh_result = double
        allow(ssh_result).to receive(:exitstatus).and_return(1)
        allow(ssh_result).to receive(:to_s).and_return("Failed to cat foo: no such file or directory")
        expect(ssh).to receive(:"exec!").and_return(ssh_result)
        expect(Net::SSH).to receive(:start).with("puppetserver.example.net", "foo", extra: "bar").and_yield(ssh)
        expect { described_class.facts(node, config) }.to raise_error(/ssh failed with exitcode=1: Failed to cat foo/)
      end

      it "should return data if SSH call succeeds" do
        config = { "ssh" => { "server" => "puppetserver.example.net", "user" => "foo", "extra" => "bar" } }
        ssh = double
        ssh_result = double
        allow(ssh_result).to receive(:exitstatus).and_return(0)
        allow(ssh_result).to receive(:to_s).and_return("---\nname: #{node}\nvalues:\n  foo: bar\n")
        expect(ssh).to receive(:"exec!").and_return(ssh_result)
        expect(Net::SSH).to receive(:start).with("puppetserver.example.net", "foo", extra: "bar").and_yield(ssh)
        expect(described_class.facts(node, config)).to eq("name" => node, "values" => { "foo" => "bar" })
      end
    end
  end
end
