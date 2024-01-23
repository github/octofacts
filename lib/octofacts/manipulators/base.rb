# frozen_string_literal: true
module Octofacts
  class Manipulators
    # Delete a fact from a hash.
    #
    # fact_set  - The hash of facts
    # fact_name - Fact to delete, either as a string, symbol, or "multi::level::hash::key"
    def self.delete(fact_set, fact_name)
      if fact_name.to_s !~ /::/
        fact_set.delete(fact_name.to_sym)
        return
      end

      # Convert level1::level2::level3 into { "level1" => { "level2" => { "level3" => ... } } }
      # The delimiter is 2 colons.
      levels = fact_name.to_s.split("::")
      key_name = levels.pop.to_sym
      pointer = fact_set
      while levels.any?
        next_key = levels.shift.to_sym
        return unless pointer.key?(next_key) && pointer[next_key].is_a?(Hash)
        pointer = pointer[next_key]
      end

      pointer.delete(key_name)
    end

    # Determine if a fact exists in a hash.
    #
    # fact_set  - The hash of facts
    # fact_name - Fact to check, either as a string, symbol, or "multi::level::hash::key"
    #
    # Returns true if the fact exists, false otherwise.
    def self.exists?(fact_set, fact_name)
      !get(fact_set, fact_name).nil?
    end

    # Retrieves the value of a fact from a hash.
    #
    # fact_set  - The hash of facts
    # fact_name - Fact to retrieve, either as a string, symbol, or "multi::level::hash::key"
    #
    # Returns the value of the fact.
    def self.get(fact_set, fact_name)
      return fact_set[fact_name.to_sym] unless fact_name.to_s =~ /::/

      # Convert level1::level2::level3 into { "level1" => { "level2" => { "level3" => ... } } }
      # The delimiter is 2 colons.
      levels = fact_name.to_s.split("::")
      key_name = levels.pop.to_sym
      pointer = fact_set
      while levels.any?
        next_key = levels.shift.to_sym
        return unless pointer.key?(next_key) && pointer[next_key].is_a?(Hash)
        pointer = pointer[next_key]
      end
      pointer[key_name]
    end

    # Sets the value of a fact in a hash.
    #
    # The new value can be a string, integer, etc., which will directly set the value of
    # the fact. Instead, you may pass a lambda in place of the value, which will evaluate
    # with three parameters: lambda { |fact_set|, |fact_name|, |old_value| ... },
    # or with one parameter: lambda { |old_value| ...}.
    # If the value of the fact as evaluated is `nil` then the fact is deleted instead of set.
    #
    # fact_set  - The hash of facts
    # fact_name - Fact to set, either as a string, symbol, or "multi::level::hash::key"
    # value     - A lambda with new code, or a string, integer, etc.
    def self.set(fact_set, fact_name, value)
      fact = fact_name.to_s

      if fact !~ /::/
        fact_set[fact_name.to_sym] = _set(fact_set, fact_name, fact_set[fact_name.to_sym], value)
        fact_set.delete(fact_name.to_sym) if fact_set[fact_name.to_sym].nil?
        return
      end

      # Convert level1::level2::level3 into { "level1" => { "level2" => { "level3" => ... } } }
      # The delimiter is 2 colons.
      levels = fact_name.to_s.split("::")
      key_name = levels.pop.to_sym
      pointer = fact_set
      while levels.any?
        next_key = levels.shift.to_sym
        pointer[next_key] = {} unless pointer[next_key].is_a? Hash
        pointer = pointer[next_key]
      end
      pointer[key_name] = _set(fact_set, fact_name, pointer[key_name], value)
      pointer.delete(key_name) if pointer[key_name].nil?
    end

    # Internal method: Determine the value you're setting to.
    #
    # This handles dispatching to the lambda function or putting the new value in place.
    def self._set(fact_set, fact_name, old_value, new_value)
      if new_value.is_a?(Proc)
        if new_value.arity == 1
          new_value.call(old_value)
        elsif new_value.arity == 3
          new_value.call(fact_set, fact_name, old_value)
        else
          raise ArgumentError, "Lambda method expected 1 or 3 parameters, got #{new_value.arity}"
        end
      else
        new_value
      end
    end
  end
end
