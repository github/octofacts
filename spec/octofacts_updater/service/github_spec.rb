require "spec_helper"

require "ostruct"

describe OctofactsUpdater::Service::GitHub do
  before(:each) do
    ENV["OCTOKIT_TOKEN"] = "00decaf"
  end

  after(:each) do
    ENV.delete("OCTOKIT_TOKEN")
  end

  describe "#run" do
    it "should raise error if base directory is not specified" do
      paths = %w{/tmp/foo/spec/fixtures/nodes/foo.yaml /tmp/foo/spec/fixtures/index.yaml}
      options = {}
      obj = instance_double(described_class)
      expect { described_class.run(nil, paths, options) }.to raise_error(ArgumentError)
    end

    it "should raise error if base directory is not found" do
      root = "/tmp/foo"
      paths = %w{/tmp/foo/spec/fixtures/nodes/foo.yaml /tmp/foo/spec/fixtures/index.yaml}
      options = {}
      obj = instance_double(described_class)
      allow(File).to receive(:directory?).and_call_original
      allow(File).to receive(:directory?).with("/tmp/foo").and_return(false)
      expect { described_class.run(root, paths, options) }.to raise_error(ArgumentError)
    end

    it "should call the appropriate methods from the workflow" do
      root = "/tmp/foo"
      paths = %w{/tmp/foo/spec/fixtures/nodes/foo.yaml /tmp/foo/spec/fixtures/index.yaml}
      options = {}

      obj = instance_double(described_class)
      expect(described_class).to receive(:new).with(options).and_return(obj)

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("/tmp/foo/spec/fixtures/nodes/foo.yaml").and_return("foo!")
      allow(File).to receive(:read).with("/tmp/foo/spec/fixtures/index.yaml").and_return("index!")

      allow(File).to receive(:directory?).and_call_original
      allow(File).to receive(:directory?).with("/tmp/foo").and_return(true)

      expect(obj).to receive(:commit_data).with("spec/fixtures/nodes/foo.yaml", "foo!")
      expect(obj).to receive(:commit_data).with("spec/fixtures/index.yaml", "index!")

      expect(obj).to receive(:finalize_commit)

      described_class.run(root, paths, options)
    end
  end

  describe "#initialize" do
    it "should construct octokit object when appropriate configuration is supplied" do
      config = { "github" => { "token" => "beefbeef" } }
      subject = described_class.new(config)
      expect(subject.send(:octokit)).to be_a_kind_of(Octokit::Client)
      expect(subject.send(:octokit).access_token).to eq("beefbeef")
    end

    it "should use octokit token from the enviroment" do
      subject = described_class.new({})
      expect(subject.send(:octokit)).to be_a_kind_of(Octokit::Client)
      expect(subject.send(:octokit).access_token).to eq("00decaf")
    end

    it "should raise an error when token is missing from configuration" do
      ENV.delete("OCTOKIT_TOKEN")
      config = { "github" => {} }
      obj = described_class.new(config)
      expect { obj.send(:octokit) }.to raise_error(ArgumentError)
    end
  end

  describe "#commit_data" do
    let(:cfg) { { "github" => { "branch" => "foo", "repository" => "example/repo" } } }

    context "when the file is found in the repo and it has not changed" do
      let(:old_content) { Base64.encode64 "this is the content" }
      let(:new_content) { "this is the content" }
      let(:octokit_args) { {path: "foo/bar/baz.yaml", ref: "foo"} }

      before(:each) do
        octokit = double("Octokit")
        allow(octokit).to receive(:contents).with("example/repo", octokit_args).and_return(OpenStruct.new(content: old_content))
        @subject = described_class.new(cfg)
        allow(@subject).to receive(:octokit).and_return(octokit)
        expect(@subject).to receive(:ensure_branch_exists)
        expect(@subject).to receive(:verbose).with("Content of foo/bar/baz.yaml matches, no commit needed")
        @result = @subject.commit_data("foo/bar/baz.yaml", new_content)
      end

      it "should return false" do
        expect(@result).to eq(false)
      end

      it "should not appear in the @changes array" do
        expect(@subject.instance_variable_get("@changes")).to eq([])
      end
    end

    context "when the file is found in the repo and it has changed" do
      let(:old_content) { Base64.encode64 "this is the old content" }
      let(:new_content) { "this is the new content" }
      let(:octokit_args) { {path: "foo/bar/baz.yaml", ref: "foo"} }

      before(:each) do
        octokit = double("Octokit")
        allow(octokit).to receive(:contents).with("example/repo", octokit_args).and_return(OpenStruct.new(content: old_content))
        allow(octokit).to receive(:create_blob).with("example/repo", new_content)
        @subject = described_class.new(cfg)
        allow(@subject).to receive(:octokit).and_return(octokit)
        expect(@subject).to receive(:ensure_branch_exists)
        expect(@subject).to receive(:verbose).with("Content of foo/bar/baz.yaml does not match. A commit is needed.")
        expect(@subject).to receive(:verbose).with("Batched update of foo/bar/baz.yaml")
        expect(@subject).to receive(:verbose).with(Diffy::Diff)
        @result = @subject.commit_data("foo/bar/baz.yaml", new_content)
      end

      it "should return true" do
        expect(@result).to eq(true)
      end

      it "should appear in the @changes array" do
        expect(@subject.instance_variable_get("@changes")).to eq([{path: "foo/bar/baz.yaml", mode: "100644", type: "blob", sha: nil}])
      end
    end

    context "when the file is not found in the repo" do
      let(:new_content) { "this is the new content" }
      let(:octokit_args) { {path: "foo/bar/baz.yaml", ref: "foo"} }

      before(:each) do
        octokit = double("Octokit")
        allow(octokit).to receive(:contents).with("example/repo", octokit_args).and_raise(Octokit::NotFound)
        allow(octokit).to receive(:create_blob).with("example/repo", new_content)
        @subject = described_class.new(cfg)
        allow(@subject).to receive(:octokit).and_return(octokit)
        expect(@subject).to receive(:ensure_branch_exists)
        expect(@subject).to receive(:verbose).with("No old content found in \"example/repo\" at \"foo/bar/baz.yaml\" in \"foo\"")
        expect(@subject).to receive(:verbose).with("Content of foo/bar/baz.yaml does not match. A commit is needed.")
        expect(@subject).to receive(:verbose).with("Batched update of foo/bar/baz.yaml")
        expect(@subject).to receive(:verbose).with(Diffy::Diff)
        @result = @subject.commit_data("foo/bar/baz.yaml", new_content)
      end

      it "should return true" do
        expect(@result).to eq(true)
      end

      it "should appear in the @changes array" do
        expect(@subject.instance_variable_get("@changes")).to eq([{path: "foo/bar/baz.yaml", mode: "100644", type: "blob", sha: nil}])
      end
    end
  end

  describe "#finalize_commit" do
    let(:cfg) { { "github" => { "branch" => "foo", "repository" => "example/repo", "commit_message" => "Hi" } } }
    let(:octokit) { double("Octokit") }
    let(:subject) { described_class.new(cfg) }

    context "with no changes" do
      it "should do nothing" do
        subject.instance_variable_set("@changes", [])
        expect(subject).not_to receive(:ensure_branch_exists)
        subject.finalize_commit
      end
    end

    context "with changes" do
      it "should make the expected octokit calls" do
        subject.instance_variable_set("@changes", [{path: "foo/bar/baz.yaml", mode: "100644", type: "blob", sha: nil}])
        expect(subject).to receive(:ensure_branch_exists).and_return(true)
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(octokit).to receive(:branch).with("example/repo", "foo").and_return(commit: { sha: "00abcdef" })
        expect(octokit).to receive(:git_commit)
          .with("example/repo", "00abcdef")
          .and_return("sha" => "abcdef00", "tree" => { "sha" => "abcdef00" })
        expect(octokit).to receive(:create_tree)
          .with("example/repo", [{path: "foo/bar/baz.yaml", mode: "100644", type: "blob", sha: nil}], {base_tree: "abcdef00"})
          .and_return("sha" => "abcdef00")
        expect(octokit).to receive(:create_commit)
          .with("example/repo", "Hi", "abcdef00", "abcdef00")
          .and_return("sha" => "abcdef00")
        expect(octokit).to receive(:update_ref)
          .with("example/repo", "heads/foo", "abcdef00")
        expect(subject).to receive(:verbose).with("Committed 1 change(s) to GitHub")
        expect(subject).to receive(:find_or_create_pull_request)
        subject.finalize_commit
      end
    end
  end

  describe "#delete_file" do
    let(:cfg) { { "github" => { "branch" => "foo", "repository" => "example/repo", "commit_message" => "Hi" } } }
    let(:octokit) { double("Octokit") }
    let(:subject) { described_class.new(cfg) }

    context "when the file exists" do
      it "should send an octokit commit to delete the file" do
        expect(subject).to receive(:ensure_branch_exists)
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(octokit).to receive(:contents)
          .with("example/repo", {path: "foo/bar/baz.yaml", ref: "foo"})
          .and_return(OpenStruct.new(sha: "00abcdef"))
        expect(octokit).to receive(:delete_contents)
          .with("example/repo", "foo/bar/baz.yaml", "Hi", "00abcdef", {branch: "foo"})
        expect(subject).to receive(:verbose).with("Deleted foo/bar/baz.yaml")
        expect(subject).to receive(:find_or_create_pull_request)
        expect(subject.delete_file("foo/bar/baz.yaml")).to eq(true)
      end
    end

    context "with the file does not exist" do
      it "should do nothing" do
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(subject).to receive(:ensure_branch_exists)
        expect(octokit).to receive(:contents)
          .with("example/repo", {path: "foo/bar/baz.yaml", ref: "foo"})
          .and_raise(Octokit::NotFound)
        expect(subject).to receive(:verbose).with("Deleted foo/bar/baz.yaml (already gone)")
        expect(subject).not_to receive(:find_or_create_pull_request)
        expect(subject.delete_file("foo/bar/baz.yaml")).to eq(false)
      end
    end
  end

  describe "#default_branch" do
    it "should return the branch from the options" do
      opts = { "github" => { "default_branch" => "cuddly-kittens", "repository" => "example/repo-name", "token" => "00decaf" } }
      subject = described_class.new(opts)
      expect(subject.send(:default_branch)).to eq("cuddly-kittens")
    end

    it "should return the branch from octokit" do
      opts = { "github" => { "repository" => "example/repo-name", "token" => "00decaf" } }
      fake_octokit = double("Octokit")
      allow(fake_octokit).to receive(:repo).with("example/repo-name").and_return(default_branch: "adorable-kittens")
      subject = described_class.new(opts)
      allow(subject).to receive(:octokit).and_return(fake_octokit)
      expect(subject.send(:default_branch)).to eq("adorable-kittens")
    end
  end

  describe "#ensure_branch_exists" do
    let(:cfg) { { "github" => { "branch" => "foo", "repository" => "example/repo", "default_branch" => "master" } } }
    let(:octokit) { double("Octokit") }
    let(:subject) { described_class.new(cfg) }

    context "when branch exists" do
      it "should not create branch" do
        allow(octokit).to receive(:branch).with("example/repo", "foo").and_return(true)
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(subject).to receive(:verbose).with("Branch foo already exists in example/repo.")
        expect(subject.send(:ensure_branch_exists)).to eq(true)
      end
    end

    context "when branch does not exist" do
      it "should create branch of Octokit::NotFound is raised" do
        allow(octokit).to receive(:branch).with("example/repo", "foo").and_raise(Octokit::NotFound)
        allow(octokit).to receive(:branch).with("example/repo", "master").and_return(commit: { sha: "00abcdef" })
        expect(octokit).to receive(:create_ref).with("example/repo", "heads/foo", "00abcdef")
        expect(subject).to receive(:verbose).with("Created branch foo based on master 00abcdef.")
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(subject.send(:ensure_branch_exists)).to eq(true)
      end

      it "should create branch if .branch call returns nil" do
        allow(octokit).to receive(:branch).with("example/repo", "foo").and_return(nil)
        allow(octokit).to receive(:branch).with("example/repo", "master").and_return(commit: { sha: "00abcdef" })
        expect(octokit).to receive(:create_ref).with("example/repo", "heads/foo", "00abcdef")
        expect(subject).to receive(:verbose).with("Created branch foo based on master 00abcdef.")
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(subject.send(:ensure_branch_exists)).to eq(true)
      end
    end
  end

  describe "#find_or_create_pull_request" do
    let(:cfg) { { "github" => { "branch" => "foo", "repository" => "example/repo", "default_branch" => "master" } } }
    let(:subject) { described_class.new(cfg) }
    let(:pr) { OpenStruct.new(html_url: "https://github.com/example/repo/pull/12345") }

    context "when PRs are returned" do
      it "should return the first matching PR" do
        octokit = double("Octokit")
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(octokit).to receive(:pull_requests).with("example/repo", {head: "github:foo", state: "open"}).and_return([pr])
        expect(subject).to receive(:verbose).with("Found existing PR https://github.com/example/repo/pull/12345")
        result = subject.send(:find_or_create_pull_request)
        expect(result).to eq(pr)
      end
    end

    context "when PRs are not returned" do
      it "should create a new PR and return it" do
        octokit = double("Octokit")
        allow(subject).to receive(:octokit).and_return(octokit)
        expect(octokit).to receive(:pull_requests).with("example/repo", {head: "github:foo", state: "open"}).and_return([])
        expect(octokit).to receive(:create_pull_request).with("example/repo", "master", "foo", "PR_Subject", "PR_Body").and_return(pr)
        expect(subject).to receive(:verbose).with("Created a new PR https://github.com/example/repo/pull/12345")
        expect(subject).to receive(:pr_subject).and_return("PR_Subject")
        expect(subject).to receive(:pr_body).and_return("PR_Body")
        result = subject.send(:find_or_create_pull_request)
        expect(result).to eq(pr)
      end
    end
  end
end
