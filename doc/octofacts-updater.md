# Configuring octofacts-updater

`octofacts-updater` is a command line utility that anonymizes and sanitizes facts, builds and maintains index files, and (optionally) interacts directly with the GitHub API to create pull requests if there are any changes.

If you followed the [quick start tutorial](/doc/tutorial.md), you manually obtained a fact fixture by running `facter` on a host. However, since you did so without setting up a configuration file, your fact fixture may have contained sensitive information (e.g. the private SSH keys for the host). You also had to SSH into a host manually to run `facter` which is non-ideal for an automated setup.

This document will help you address all of these security and automation non-optimalities.

## Configuration file quick start

The easiest way to get started with `octofacts-updater` is to download and install our "quickstart" configuration file. In the git repo, this is found at [/examples/config/quickstart.yaml](/examples/config/quickstart.yaml). If you'd like to download the latest version directly from GitHub, you can use wget, like this:

```
wget -O octofacts-updater.yaml https://raw.githubusercontent.com/github/octofacts/master/examples/config/quickstart.yaml
```

## Data sources

`octofacts-updater` can obtain facts from the following data sources:

- Local files
- PuppetDB
- SSH

`octofacts-updater` will attempt to obtain facts from each of those data sources, in the order listed above. If retrieving facts from one data source succeeds, the subsequent data sources will not be contacted. If all of the data sources are unconfigured or fail, then an error is raised.

If you are running `octofacts-updater` from the command line, you can force a specific data source to be used with the `--datasource` option. For example:

```
octofacts-updater --datasource localfiles ...
octofacts-updater --datasource puppetdb ...
octofacts-updater --datasource ssh ...
```

### Local files

As seen in the [quick start tutorial](/doc/tutorial.md), if you make the facts for a node available in a YAML file, `octofacts-updater` can import it. This is great for testing, but it can also be used in complex environments where you cannot easily use the other built-in capabilities. In such a case, you can generate the YAML file with facts via some other method, and then import the result into octofacts.

There is no configuration needed in the `octofacts-updater` configuration file for the local file data source. Simply provide the full path to the file containing the facts on the command line as follows:

```
octofacts-updater --datasource localfiles --config-override localfile:path=/tmp/facts.yaml --hostname <hostname> ...
```

### PuppetDB

`octofacts-updater` can connect to PuppetDB (version 3.0 or higher) and retrieve the facts from the most recently reported run of Puppet on the node.

You can configure the PuppetDB connection by supplying the URL in the `octofacts-updater` configuration file.

```title=octofacts-updater.yaml
puppetdb:
  url: https://puppetdb.example.net:8081
```

### SSH

`octofacts-updater` can SSH to a node and run the command of your choice. There are two common strategies for this option: obtaining the facts from the cache of a puppetserver, or contacting an actual node to ask for its facts.

When configuring SSH connectivity, you must supply the following parameters:

- `server`: The system to SSH to.
- `user`: The user to log in as.
- `command`: The command to run on the target system.

You may use `%%NODE%%` in either the `server` or `command` parameter. This will be replaced with the hostname you have requested via the `--hostname` parameter.

Under the hood, `octofacts-updater` uses the [Ruby net-ssh gem](https://github.com/net-ssh/net-ssh). Any other options you supply to the `ssh` section will be symbolized and passed to the module. For example, you may use:

- `password`: Hard-code a password, instead of using public key authentication.
- `port`: Choose a port other than the default port, 22.
- `passphrase`: Hard-code the passphrase for a key.

#### Obtaining the facts from the cache of a puppetserver

In its default installation, the puppetserver will save a copy of the most recent facts for a node in the `/opt/puppetlabs/server/data/puppetserver/yaml/facts` directory. You can configure `octofacts-updater` to SSH to the puppetserver and `cat` the node's file.

```title=octofacts-updater.yaml
ssh:
  server: puppetserver.example.net
  user: puppet
  command: cat /opt/puppetlabs/server/data/puppetserver/yaml/facts/%%NODE%%.yaml
```

Note that the `/opt/puppetlabs/server/data/puppetserver/yaml/facts` may be limited, via Unix file permissions, to be accessible only to a `puppet` user. You may need to work around this by adding the `user` to an appropriate group, or by enabling the command to run under `sudo` without a password.

#### Contacting an actual node to ask for its facts

The SSH data source can be leveraged to contact the node whose facts are being determined, by using `%%NODE%%` as the server name. The following command will contact the node in question and run `facter` to get the facts in YAML format.

```title=octofacts-updater.yaml
ssh:
  server: %%NODE%%
  user: puppet
  command: /opt/puppetlabs/puppet/bin/facter -p --yaml
```

Note that `facter` may need to run as root to gather all of the facts for the system. You may need to work around this by enabling the command to run under `sudo` without a password.

Also, if you are using Puppet 4 or later, but are relying on "legacy" facts that were used in Puppet 3, you may need to add `--show-legacy` to the `facter` command line.

## Anonymizing and rewriting facts

To avoid committing sensitive information into source control, and to prevent rspec-puppet tests from inadvertently contacting actual systems, `octofacts-updater` supports anonymizing and rewriting facts. For example, you might remove or scramble SSH keys, delete or hard-code facts like system uptime that change upon each run, or change IP addresses.

You can configure this in the `octofacts-updater` configuration file. The [quickstart example configuration](/examples/config/quickstart.yaml) contains several examples.

`octofacts-updater` comes with several pre-built methods to adjust facts, and supports a plugin system to allow users to extend the functionality in their own environment. (If you write a plugin that you believe may be of general use, please check our [Contributing Document](/CONTRIBUTING.md) and look in the [plugins directory](/lib/octofacts_updater/plugins).)

To configure fact adjusting, define `facts` as a hash in the configuration file, with one entry per adjustment.

### Common actions

#### Deleting facts

If a fact does not contain useful information to your Puppet code, you may choose to remove it from the fact fixtures.

The following example will delete the `ec2_userdata` fact:

```
facts:
  ec2_userdata:
    plugin: delete
```

#### Setting fact to a static value

If a fact changes frequently, you may choose to set it to a static value. This will avoid making changes to the fact fixtures each time the updater runs.

The following example will set the `uptime_seconds` fact to `12345`, which will avoid rewriting the value of this fact each time the updater runs:

```
facts:
  uptime_seconds:
    plugin: set
    value: 12345
```

#### Obscuring SSH private keys

To avoid committing the SSH private key of a node (or any similar credential) into source control, you can use the `randomize_long_string` plugin. This will generate a string of random characters that is the same length as the original key.

The [quickstart example configuration](/examples/config/quickstart.yaml) invokes this for the standard SSH facts. In the following example, all facts that match the regular expression will have their values randomized.

```
facts:
  ssh_keys:
    regexp: ^ssh\w+key$
    plugin: randomize_long_string
```

Note that it is not possible to reconstruct the original key from the random key; however, the original key is used to seed the random number generator so the random key will be consistent so long as the original key does not change.

#### Randomizing IP addresses

To prevent rspec-puppet tests from contacting or accessing actual hosts, you may choose to use random IP addresses to replace actual IP addresses. (Best practice would dictate that you isolate your continuous integration environment from your production environment, but this doesn't always happen...)

You can use the IP anonymization plugin to adjust `ipaddress` fact as follows:

```
facts:
  ipaddress:
    plugin: ipv4_anonymize
    subnet: "10.0.1.0/24"
```

The original IP address is used to seed the random number generator, so the random IP address chosen will be consistent so long as the original IP address does not change. There is a corresponding `ipv6_anonymize` plugin to generate random IPv6 addresses on a specified IPv6 subnet.

### Handling structured or multiple facts

Structured facts are organized in a hash structure, like in this example:

```
ssh:
  dsa:
    fingerprints:
      sha1: SSHFP 2 1 abcdefabcdefabcdefabcdefabcdefabcdefabcd
      sha256: SSHFP 2 2 abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd
    key: AAAAxxxxxxxxxxxx...
  ecdsa:
    fingerprints:
      sha1: SSHFP 3 1 abcdefabcdefabcdefabcdefabcdefabcdefabcd
      sha256: SSHFP 3 2 abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd
    key: AAAAxxxxxxxxxxxx...
  ...
```

It is possible to use regular expressions to "dig" into the structure with the following format:

```
facts:
  ssh:
    structure:
      - regexp: .+
      - regexp: ^key$
    plugin: randomize_long_string
```

In the example above, the code will explore the structured fact named `ssh`. At the first level, it will match the regular expression `.+` (which is any number of any character, i.e., every element). Then in each matching level, it will match the regular expression `^key$` (which is an exact match of the string "key"). For each match, the plugin will be executed. In the example above:

```
ssh:
  dsa:
    fingerprints:
      sha1: SSHFP 2 1 abcdefabcdefabcdefabcdefabcdefabcdefabcd
      sha256: SSHFP 2 2 abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd
    key: THIS_IS_RANDOMIZED...
  ecdsa:
    fingerprints:
      sha1: SSHFP 3 1 abcdefabcdefabcdefabcdefabcdefabcdefabcd
      sha256: SSHFP 3 2 abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd
    key: THIS_IS_RANDOMIZED...
  ...
```

### Extending `octofacts-updater` with plugins

`octofacts-updater` supports a plugin architecture to add additional fact anonymizers. The methods included with the gem are also written in this plugin architecture. You can read the [plugin reference documentation](/doc/plugin-reference.md) or browse the [plugins directory](/lib/octofacts_updater/plugins).

If you find yourself needing to create additional plugins for your site-specific needs, you can include those plugins by placing entries in the octofacts-updater configuration file that reference the files where those plugins exist:

```title=octofacts-updater.yaml
plugins:
  - /usr/local/lib/octofacts-updater/custom-plugins.rb
  - /usr/local/lib/octofacts-updater/more-plugins.rb
```

Each plugin is created with code in the following general structure:

```title=plugin.rb
# Plugin name: name_of_plugin
#
# fact  - OctofactsUpdater::Fact object of the fact being manipulated
# args  - Hash with arguments specified in the configuration file (e.g. "structure" plus any other parameters)
# facts - Hash of { fact_name, OctofactsUpdater::Fact } for every fact defined (in case one fact needs to reference another)
#
# The method should adjust `fact` by calling methods such as `.set_value`. It should NOT modify `args` or `facts`.
#
OctofactsUpdater::Plugin.register(:name_of_plugin) do |fact, args = {}, facts|
  value = fact.value
  new_value = # Your code here
  fact.set_value(new_value)
end
```

## Automating Pull Request creation with GitHub

To configure `octofacts-updater` to push changes to a branch on GitHub and open pull requests, use the following configuration:

```title=octofacts-updater.yaml
github:
  branch: octofacts-updater
  pr_subject: Automated fact fixture update for octofacts
  pr_body: A nice inspiring and helpful message to yourself
  repository: example/puppet
  commit_message: Automated fact fixture update for octofacts
  base_directory: /Users/hubot/projects/puppet
  # token: We recommend that you set ENV["OCTOKIT_TOKEN"] instead of hard-coding a token here.
```

#### Your personal access token

Head to [https://github.com/settings/tokens](https://github.com/settings/tokens) to generate an access token.

It is possible to place the token into the configuration file like:

```
github:
  token: abcdefg1234567
```

However, we recommend that you do not do this, especially if the configuration file is going to be checked in to a source code repository. Instead, you may set the environment variable `OCTOKIT_TOKEN` with the contents of your token. ("octokit" is a reference to the [octokit gem](https://github.com/octokit/octokit.rb), which underlies the GitHub integration of `octofacts-updater`.)

#### Using the GitHub integration

1. The GitHub integration is only available when running with `--action bulk`, as it is designed to push a comprehensive change set.

2. To trigger the GitHub integration, supply `--github` as a command line argument when running `octofacts-updater`. (This will raise an error if there is no `github` section in the configuration, or if required parameters are missing.)

3. The `base_directory` setting distinguishes between the directory paths on the system you're running on, and the repository you're committing to. As an example, consider that a user has checked out their Puppet code to `/Users/hubot/projects/puppet` and their octofacts-managed fact fixtures are in `/Users/hubot/projects/puppet/spec/fixtures/facts/octofacts`. They want to create and manage files in `spec/fixtures/facts/octofacts` within the repo, but don't want to create a `/Users/hubot/projects/puppet` directory there. As a reminder, `--config-override github:base_directory=/Users/hubot/projects/puppet` is available to override parameters in the configuration file.

#### Tips

1. Be sure that you delete the branch on GitHub once you've merged it, so that it can be recreated from the most recent default branch the next time `octofacts-updater` is executed.

2. The GitHub integration does not merge the default branch into your branch automatically. You can do this on GitHub with the "Update Branch" button.

## Putting it all together

Once you've configured your data source and paths, and optionally the integration to GitHub, it's time to run `octofacts-updater`. Assuming you've followed our examples, your command would look like this to build the initial list of fixtures:

```
bin/octofacts-updater --config octofacts-updater.yaml -a bulk -l <fqdn1>,<fqdn2>,<fqdn3>,...
```

Thereafter, the list of nodes to index will be pulled from the index file, so you won't need to list them out each time.
