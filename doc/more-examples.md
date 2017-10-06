# Octofacts examples

## Manipulating facts with built-in functions

We provide some helper functions to manipulate facts easily, since we take care of symbolizing and lower-casing keys for you:

```
describe modulename::classname do
  let(:node) { "fake-node.example.net" }
  let(:facts) { Octofacts.from_index(app: "my_app_name", role: "my_role_name").replace("fact-name", "new-value") }

  it "should do whatever..."
    ...
  end
end
```

## Manipulating facts with pure ruby

If you don't want to use our helper functions, you can use the object as a normal ruby hash:

```
describe modulename::classname do
  let(:node) { "fake-node.example.net" }
  let(:facts) do
    f = Octofacts.from_index(app: "my_app_name", role: "my_role_name")
    f.merge!(:some_fact, "new-value")
    f.delete(:some_other_fact)
    f
  end

  it "should do whatever..."
    ...
  end
end
```

## Defining your own helper functions

You can also define your own helper functions by adding them to your `spec_helper` with no need to modify our code:

```
# spec/spec_helper.rb
# --

module Octofacts
  class Manipulators
    class AddFakeDrive
      def self.execute(fact_set, args, _)
        fact_set[:blockdevices] = (fact_set[:blockdevices] || "").split(",").concat(args[0]).join(",")
        fact_set[:"blockdevice_#{args[0]}_size"] = args[1]
      end
    end
  end
end

# modules/modulename/spec/classes/classname_spec.rb
# --
describe modulename::classname do
  let(:node) { "fake-node.example.net" }
  let(:facts) { Octofacts.from_index(app: "my_app_name", role: "my_role_name").add_fake_drive("sdz", 21474836480) }

  it "should do whatever..."
    ...
  end
end
```
