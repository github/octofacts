# octofacts

`octofacts` is a tool that enables Puppet developers to provide complete sets of facts for rspec-puppet tests. It works by saving facts from actual hosts as fixture files, and then presenting a straightforward programming interface to select and manipulate those facts within tests. Using nearly real-life facts is a good way to ensure that rspec-puppet tests match production as closely as possible.

`octofacts` is actively used in production at [GitHub](https://github.com). This project is actively maintained by the original authors and the rest of the Site Reliability Engineering team at GitHub.

## Overview

The `octofacts` project is distributed with two components:

- The `octofacts` gem is called within your rspec-puppet tests, to provide facts from indexed fact fixture files in your repository. This allows you to replace a hard-coded `let (:facts) { ... }` hash with more realistic facts from recent production runs.

- The `octofacts-updater` gem is a utility to maintain the indexed fact fixture files consumed by `octofacts`. It pulls facts from a data source (e.g. PuppetDB, fact caches, or SSH), indexes your facts, and can even create Pull Requests on GitHub to update those fixture files for you.

## Requirements

To use `octofacts` in your rspec-puppet tests, those tests must be executed with Ruby 2.1 or higher and rspec-puppet 2.3.2 or higher, and executed on a Unix-like operating system. We explicitly test `octofacts` with Linux and Mac OS, but do not test under Windows.

To use `octofacts-updater`, we recommend using PuppetDB, and if you do you'll need version 3.0 or higher.

## Example

Once you complete the initial setup and generate fact fixtures, you'll be able to use code like this in your rspec-puppet tests:

```
describe "modulename::classname" do
  let(:node) { "fake-node.example.net" }
  let(:facts) { Octofacts.from_index(app: "my_app_name", role: "my_role_name") }

  it "should do whatever..."
    ...
  end
end
```

## Installation and use

The basics:

- [Quick start tutorial - covers installation and basic configuration](/doc/tutorial.md) <-- **New users start here**
- [Automating fixture generation with octofacts-updater](/doc/octofacts-updater.md)

More advanced usage:

- [Plugin reference for octofacts-updater](/doc/plugin-reference.md)
- [Using manipulators to adjust fact values](/doc/manipulators.md)
- [Additional examples of octofacts capabilities](/doc/more-examples.md)

## Contributing

Please see our [contributing document](CONTRIBUTING.md) if you would like to participate!

We would specifically appreciate contributions in these areas:

- Any updates you make to make octofacts compatible with your site -- there are probably assumptions made from the original environment that need to be more flexible.
- Any interesting anonymization plugins you write for octofacts-updater -- you may place these in the [contrib/plugins](/contrib/plugins) directory.

## Getting help

If you have a problem or suggestion, please [open an issue](https://github.com/github/octofacts/issues/new) in this repository, and we will do our best to help. Please note that this project adheres to its [Code of Conduct](/CODE_OF_CONDUCT.md).

## License

`octofacts` is licensed under the [MIT license](/LICENSE).

## Authors

- [@antonio - Antonio Santos](https://github.com/antonio)
- [@kpaulisse - Kevin Paulisse](https://github.com/kpaulisse)
