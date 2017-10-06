# Manipulators - Modifying facts before use

Octofacts provides the capability to modify facts before they are passed to `rspec-puppet`. We provide certain methods to make this easier and more human-readable, but it is also possible to use regular ruby if you prefer.

## Available manipulators

### `.replace` - Replace or set facts

For example, this replaces two facts with string values:

```
Octofacts.from_index(environment: "test").replace(operatingsystem: "Debian", lsbdistcodename: "jessie")
```

It is also possible to perform replacements in structured facts, using `::` as the delimiter.

```
Octofacts.from_index(environment: "test").replace("os::name" => "Debian", "os::lsb::distcodename" => "jessie")
```

*Note*: It doesn't matter if the fact you're trying to "replace" currently exists. The "replace" method will set the fact to your new value regardless of whether that fact existed before.

*Note*: If you attempt to set a structured fact and the intermediate hash structure does not exist, that intermediate hash structure will be auto-created as necessary so that the fact you defined can be created. Example:

```
# Current fact value: foo = { "existing_level" => { "foo" => "bar" } }
Octofacts.from_index(...).replace("foo::new_level::test" => "value")
#=> foo = { "existing_level" => { "foo" => "bar" }, "new_level" => { "test" => "value" } }
```

*Note*: The "replace" method accepts keys (fact names) both as strings and as symbols. `.replace(foo: "bar")` and `.replace("foo" => "bar")` are equivalent.

## Advanced

### Using regular ruby

If you prefer to use regular ruby without using (or after using) our manipulators, you are free to do so. For example:

```
let(:facts) do
  f = Octofacts.from_index(environment: "test")
  f.merge!(foo: "FOO", bar: "BAR")
  f.delete(:baz)
  f
end
```

### Using lambdas as new values

It is possible to use lambda methods to assign new values using the "replace" method, to perform a programmatic replacement based on the existing values. For example:

```
Octofacts.from_index(environment: "test").replace(operatingsystem: lambda { |old_value| old_value.upcase })
#=> operatingsystem = "DEBIAN"
```

The lambda method can be defined with one parameter or three parameters as follows.

```
# One parameter - operates on the old value of the fact
lambda { |old_value| ... }

# Three parameters - takes into account the entire fact set
# 1. fact_set  - The Hash of all of the current facts
# 2. fact_name - The name of the fact being operated upon
# 3. old_value - The current (old) value of the fact
lambda { |fact_set, fact_name, old_value| ... }
```

*Note*: If a lambda function returns `nil`, the key is deleted.

## Limitations

### Order is important

#### Left to right evaluation

Evaluation is from left to right. Operations performed later in the chain may be influenced by, and/or take precedence over, earlier operations. For example:

```
Octofacts.from_index(environment: "test").replace(foo: "bar").replace(foo: "baz")
#=> foo = "baz"
```

#### Select before manipulating

It is *not* possible to use fact selector methods (e.g. `.select`, `.reject`, `.prefer`) after performing manipulations. This is because backends may be tracking multiple possible sets of facts, but manipulating the facts will internally select a set of facts before proceeding. An error message is raised if, for example, you try this:

```
Octofacts.from_index(environment: "test").replace(foo: "bar").select(operatingsystem: "Debian")
#=> Error!
```

You can instead do this, which works fine:

```
Octofacts.from_index(environment: "production").select(operatingsystem: "Debian").replace(foo: "bar")
#=> Works
```
