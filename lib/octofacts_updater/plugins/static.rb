# This file is part of the octofacts updater fact manipulation plugins. This plugin provides
# frozen_string_literal: true
# methods to do static operations on facts -- delete, add, or set to a known value.

# Delete. This method deletes the fact or the identified portion. Setting the value to nil
# causes the tooling to remove any such portions of the value.
#
# Supported parameters in args:
# - structure: A String or Array of a structure within a structured fact
OctofactsUpdater::Plugin.register(:delete) do |fact, args = {}, _all_facts = {}|
  fact.set_value(nil, args["structure"])
end

# Set. This method sets the fact or the identified portion to a static value.
#
# Supported parameters in args:
# - structure: A String or Array of a structure within a structured fact
# - value: The new value to set the fact to
OctofactsUpdater::Plugin.register(:set) do |fact, args = {}, _all_facts = {}|
  fact.set_value(args["value"], args["structure"])
end

# Remove matching objects from a delimited string. Requires that the delimiter
# and regular expression be set. This is useful, for example, to transform a
# string like `foo,bar,baz,fizz` into `foo,fizz` (by removing /^ba/).
#
# Supported parameters in args:
# - delimiter: (Required) Character that is the delimiter.
# - regexp: (Required) String used to construct a regular expression of items to remove
OctofactsUpdater::Plugin.register(:remove_from_delimited_string) do |fact, args = {}, _all_facts = {}|
  unless fact.value.nil?
    unless args["delimiter"]
      raise ArgumentError, "remove_from_delimited_string requires a delimiter, got #{args.inspect}"
    end
    unless args["regexp"]
      raise ArgumentError, "remove_from_delimited_string requires a regexp, got #{args.inspect}"
    end
    parts = fact.value.split(args["delimiter"])
    regexp = Regexp.new(args["regexp"])
    parts.delete_if { |part| regexp.match(part) }
    fact.set_value(parts.join(args["delimiter"]))
  end
end

# No-op. Do nothing at all.
OctofactsUpdater::Plugin.register(:noop) do |_fact, _args = {}, _all_facts = {}|
  #
end

# Randomize long string. This is just a wrapper around OctofactsUpdater::Plugin.randomize_long_string
OctofactsUpdater::Plugin.register(:randomize_long_string) do |fact, args = {}, _all_facts = {}|
  blk = Proc.new { |val| OctofactsUpdater::Plugin.randomize_long_string(val) }
  fact.set_value(blk, args["structure"])
end
