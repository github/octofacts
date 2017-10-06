# Octofacts quick-start tutorial

Hello there! This tutorial is intended to get you up and running quickly with octofacts, so that you can see its capabilities.

## Prerequisites

Before you get started with this tutorial, please make sure that the following prerequisites are in place.

- You should already have [rspec-puppet](http://rspec-puppet.com/) up and running for your Puppet repository.
- You should have a `spec/spec_helper.rb` file that's included in your rspec-puppet tests, as generally described in the [rspec-puppet tutorial](http://rspec-puppet.com/tutorial/).
- You should have at least one rspec-puppet test that is passing.

Additionally, we recommend that you are able to run this rspec-puppet test from your local machine. However, if you must push your changes to a source code repository (e.g. GitHub) to run the test through your CI system, that's OK too -- you'll need to commit changes and push the branches as needed.

## Installing octofacts and octofacts-updater

If you are using `bundler` to manage the gem dependencies of your Puppet repository, you can add these two gems to your Gemfile. The exact strings to add to your Gemfile can be found on rubygems:

- https://rubygems.org/gems/octofacts
- https://rubygems.org/gems/octofacts-updater

Alternatively, you can directly install octofacts and octofacts-updater into your current ruby environment using:

```
gem install octofacts octofacts-updater
```

## Creating the directory structure

The remainder of this tutorial assumes you will be using the following layout for octofacts fixture files:

```
- <base directory>/
  - spec/
    - spec_helper.rb
    - fixtures/
      - facts/
        - octofacts/
          - node-1.example.net.yaml
          - node-2.example.net.yaml
          - node-3.example.net.yaml
        - octofacts-index.yaml
```

To create the necessary directory structure, `cd` to the "spec" directory of your checkout, and then make the directories.

```
cd <base_directory>
cd spec
mkdir -p fixtures/facts/octofacts
```

## Get your first set of facts

To obtain facts from a node in the environment, we will instruct you to log in to a node and run Puppet's `facter` command, and save the resulting output in a file. Please note that the resulting file may have sensitive information (e.g. the private SSH key for the host) so you should treat it carefully.

Here is an example procedure to obtain the facts for the node, but do note that the exact procedure to do this may vary based on your own environment's setup.

```
your-workstation$ export TARGET_HOSTNAME="some-host.yourdomain.com" #<-- change as needed for your situation

your-workstation$ ssh "$TARGET_HOSTNAME"

some-host$ sudo facter -p --yaml > facts.yaml
some-host$ exit

your-workstation$ scp "$TARGET_HOSTNAME":~/facts.yaml /tmp/facts.yaml
```

Now you can run `octofacts-updater` to import this set of facts into your code repository.

```
cd <base_directory>

# If you installed with `gem install`
octofacts-updater --action facts --hostname "$TARGET_HOSTNAME" \
  --datasource localfile --config-override localfile:path=/tmp/facts.yaml \
  --output-file "spec/fixtures/facts/octofacts/${TARGET_HOSTNAME}.yaml"

# If you installed with `bundler`
bundle exec bin/octofacts-updater --action facts --hostname "$TARGET_HOSTNAME" \
  --datasource localfile --config-override localfile:path=/tmp/facts.yaml \
  --output-file "spec/fixtures/facts/octofacts/${TARGET_HOSTNAME}.yaml"

# Once you've done either of those commands, you should be able to see your file
cat "spec/fixtures/facts/octofacts/${TARGET_HOSTNAME}.yaml"
```

:warning: Until you set up anonymizers by configuring [octofacts-updater](/doc/octofacts-updater.md), the facts as you have copied may contain sensitive information (e.g. the private SSH keys for the node). Please keep this in mind before committing the newly generated file to your source code repository.

## Update your rspec-puppet spec helper to use octofacts

Add the following lines to your `spec/spec_helper.rb` file:

```title=spec_helper.rb
require "octofacts"
ENV["OCTOFACTS_FIXTURE_PATH"] ||= File.expand_path("fixtures/facts/octofacts", File.dirname(__FILE__))
ENV["OCTOFACTS_INDEX_PATH"]   ||= File.expand_path("fixtures/facts/octofacts-index.yaml", File.dirname(__FILE__))
```

Once you've done this, run one of your `rspec-puppet` tests to make sure it still passes. If you get a failure about not being able to load octofacts, this means you have not set up your gem configuration correctly.

## Update your rspec-puppet test to use the facts you just installed

Thus far you've obtained a fact fixture and configured rspec-puppet to use octofacts. You're finally ready to update one of your rspec-puppet tests to use that octofacts fixture.

Your existing test might look something like this:

```title=example_spec.rb
require 'spec_helper'

describe 'module::class' do
  let(:node) { 'some-host.yourdomain.com' }

  let(:facts) do
    {
      ...
    }
  end

  it 'should do something' do
    is_expected.to ...
  end
end
```

Change *only* the facts section to:

```
  let(:facts) { Octofacts.from_file('some-host.yourdomain.com.yaml') }
```

If there was no `:facts` section, it's possible that default facts were being set from your `spec_helper.rb`. In this case, you can simply add the line above to your test.

Now, run your test. If it passes, then congratulations -- you have successfully set up octofacts!

## Next steps

Now that you have octofacts running, you'll want to configure `octofacts-updater` to anonymize facts, create an index, and automate the maintenance of fact fixtures.

- [Configuring octofacts-updater](/doc/octofacts-updater.md)
