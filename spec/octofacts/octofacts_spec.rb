require "spec_helper"

# FIXME: Remove when real specs are added
# This has only been checked in to test our CI job

describe Octofacts::VERSION do
  it "is set" do
    expect(Octofacts::VERSION).to_not be_nil
  end
end
