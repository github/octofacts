require "spec_helper"

describe Octofacts do
  describe "#from_file" do
    before(:each) { ENV.delete("OCTOFACTS_FIXTURE_PATH") }
    after(:all) { ENV.delete("OCTOFACTS_FIXTURE_PATH") }

    it "should load from a full filename" do
      ENV["OCTOFACTS_FIXTURE_PATH"] = File.join(Octofacts::Spec.fixture_root, "does", "not", "exist")
      filename = File.join(Octofacts::Spec.fixture_root, "facts", "basic.yaml")
      test_obj = Octofacts.from_file(filename)
      expect(test_obj.facts[:ec2_ami_id]).to eq("ami-000decaf")
    end

    it "should load from a relative filename plus environment variable path" do
      ENV["OCTOFACTS_FIXTURE_PATH"] = File.join(Octofacts::Spec.fixture_root, "facts")
      filename = "basic.yaml"
      test_obj = Octofacts.from_file(filename)
      expect(test_obj.facts[:ec2_ami_id]).to eq("ami-000decaf")
    end

    it "should load from a relative filename plus provided path" do
      ENV["OCTOFACTS_FIXTURE_PATH"] = File.join(Octofacts::Spec.fixture_root, "does", "not", "exist")
      path = File.join(Octofacts::Spec.fixture_root, "facts")
      filename = "basic.yaml"
      test_obj = Octofacts.from_file(filename, octofacts_fixture_path: path)
      expect(test_obj.facts[:ec2_ami_id]).to eq("ami-000decaf")
    end

    it "should fail with no provided or environment path" do
      filename = "basic.yaml"
      expect { Octofacts.from_file(filename) }.to raise_error(ArgumentError, /.from_file needs to know :octofacts_fixture_path/)
    end

    it "should fail if the fixture path does not exist" do
      ENV["OCTOFACTS_FIXTURE_PATH"] = File.join(Octofacts::Spec.fixture_root, "does", "not", "exist")
      filename = "basic.yaml"
      expect { Octofacts.from_file(filename) }.to raise_error(Errno::ENOENT, /The provided fixture path/)
    end
  end
end
