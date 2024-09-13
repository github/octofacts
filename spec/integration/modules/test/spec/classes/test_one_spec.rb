# frozen_string_literal: true
require_relative "../../../../spec/spec_helper"

describe "test::one" do
  context "with facts hard-coded" do
    # This does not exercise octofacts. However, it helps to confirm that rspec-puppet is set
    # up correctly before we get to the tests below which do use octofacts.
    let(:facts) do
      {
        ec2: true,
        ec2_metadata: { placement: { "availability-zone": "us-foo-1a" } },
        identity: { user: "root", group: "root" },
      }
    end

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-foo-1a/
      )
    end
  end

  context "using straight octofacts from file explicitly converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml").facts }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-east-1a/
      )
    end
  end

  context "using straight octofacts from file but not converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml") }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-east-1a/
      )
    end
  end

  context "using straight octofacts from file with manipulation converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml").replace("ec2_metadata::placement::availability-zone" => "us-hats-1a").facts }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-hats-1a/
      )
    end
  end

  context "using straight octofacts from file with manipulation but not converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml").replace("ec2_metadata::placement::availability-zone" => "us-hats-1a") }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-hats-1a/
      )
    end
  end

  context "using straight octofacts from file with manipulation of symbol converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml").replace("ec2_metadata::placement::availability-zone": "us-hats-1a").facts }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-hats-1a/
      )
    end
  end

  context "using straight octofacts from file with manipulation of symbol not converted to hash" do
    let(:facts) { Octofacts.from_file("basic.yaml").replace("ec2_metadata::placement::availability-zone" => "us-hats-1a") }

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "root",
        group: "root",
        content: /availability-zone: us-hats-1a/
      )
    end
  end

  context "using pure ruby interface for manipulation" do
    context "without converting to hash" do
      let(:facts) { Octofacts.from_file("basic.yaml").merge("ec2" => false) }

      it "should contain the file resource" do
        is_expected.to contain_file("/tmp/system-info.txt").with(
          owner: "root",
          group: "root",
          content: /Not an EC2 instance/
        )
      end
    end

    context "with converting to hash" do
      let(:facts) { Octofacts.from_file("basic.yaml").facts.merge(ec2: false) }

      it "should contain the file resource" do
        is_expected.to contain_file("/tmp/system-info.txt").with(
          owner: "root",
          group: "root",
          content: /Not an EC2 instance/
        )
      end
    end
  end

  context "using chained manipulators" do
    let(:facts) do
      Octofacts.from_file("basic.yaml")
               .replace(identity: { user: "hats", group: "caps" })
               .replace(ec2: false)
    end

    it "should contain the file resource" do
      is_expected.to contain_file("/tmp/system-info.txt").with(
        owner: "hats",
        group: "caps",
        content: /Not an EC2 instance/
      )
    end
  end

  context "passing parameters to the index constructor" do
    let(:facts) { Octofacts.from_index(app: "puppet", env: "production") }

    it "should contain the file resource" do
      is_expected.to contain_file("/etc/hosts").with(
        content: /127.0.0.1 localhost puppet-puppetserver-12345/
      )
    end
  end

  context "using index + select" do
    let(:facts) { Octofacts.from_index.select(app: "puppet", env: "production") }

    it "should contain the file resource" do
      is_expected.to contain_file("/etc/hosts").with(
        content: /127.0.0.1 localhost puppet-puppetserver-12345/
      )
    end
  end

  context "using chained selectors" do
    let(:facts) { Octofacts.from_index.select(app: "puppet").reject(env: "production") }

    it "should contain the file resource" do
      is_expected.to contain_file("/etc/hosts").with(
        content: /127.0.0.1 localhost puppet-puppetserver-00decaf/
      )
    end
  end

  context "tests accessing facts as if it was a hash" do
    context "with []" do
      let(:facts) { Octofacts.from_file("basic.yaml") }

      it "should contain /etc/hosts with a symbol key" do
        is_expected.to contain_file("/etc/hosts").with(
          content: "127.0.0.1 localhost #{facts[:networking][:hostname]}"
        )
      end
    end

    context "with fetch" do
      let(:facts) { Octofacts.from_file("basic.yaml") }

      it "should contain /etc/hosts with a symbol key" do
        is_expected.to contain_file("/etc/hosts").with(
          content: "127.0.0.1 localhost #{facts.fetch(:networking, :hostname)}"
        )
      end
    end
  end

  context "tests accessing facts as if it was a string" do
    context "with []" do
      let(:facts) { Octofacts.from_file("basic.yaml") }

      it "should contain /etc/hosts with a symbol key" do
        is_expected.to contain_file("/etc/hosts").with(
          content: "127.0.0.1 localhost #{facts['networking']['hostname']}"
        )
      end
    end

    context "with fetch" do
      let(:facts) { Octofacts.from_file("basic.yaml") }

      it "should contain /etc/hosts with a symbol key" do
        is_expected.to contain_file("/etc/hosts").with(
          content: "127.0.0.1 localhost #{facts.fetch('networking', 'hostname')}"
        )
      end
    end
  end
end
