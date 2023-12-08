# frozen_string_literal: true
require_relative "manipulators/replace"

# Octofacts::Manipulators - our fact manipulation API.
# Each method in Octofacts::Manipulators will operate on one fact set at a time. These
# methods do not need to be aware of the existence of multiple fact sets.
module Octofacts
  class Manipulators
    # Locate and run manipulator.
    #
    # Returns true if the manipulator was located and executed, false otherwise.
    def self.run(obj, name, *args, &block)
      camelized_name = (name.to_s).split("_").collect(&:capitalize).join

      begin
        manipulator = Kernel.const_get("Octofacts::Manipulators::#{camelized_name}")
      rescue NameError
        return false
      end

      raise "Unable to run manipulator method '#{name}' on object type #{obj.class}" unless obj.is_a?(Octofacts::Facts)
      facts = obj.facts
      manipulator.send(:execute, facts, *args, &block)
      obj.facts = facts
      true
    end
  end
end
