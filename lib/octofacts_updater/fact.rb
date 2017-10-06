# This class represents a fact, either structured or unstructured.
# The fact has a name and a value. The name is a string, and the value
# can either be a string/integer/boolean (unstructured) or a hash (structured).
# This class also has methods used to deal with structured facts (in particular, allowing
# representation of a structure delimited with ::).

module OctofactsUpdater
  class Fact
    attr_reader :name

    # Constructor.
    #
    # name  - The String naming the fact.
    # value - The arbitrary object with the value of the fact.
    def initialize(name, value)
      @name = name
      @value = value
    end

    # Get the value of the fact. If the name is specified, this will dig into a structured fact to pull
    # out the value within the structure.
    #
    # name_in - An optional String to dig into the structure (formatted with :: indicating hash delimiters)
    #
    # Returns the value of the fact.
    def value(name_in = nil)
      # Just a normal lookup -- return the value
      return @value if name_in.nil?

      # Structured lookup returns nil unless the fact is actually structured.
      return unless @value.is_a?(Hash)

      # Dig into the hash to pull out the desired value.
      pointer = @value
      parts = name_in.split("::")
      last_part = parts.pop

      parts.each do |part|
        return unless pointer[part].is_a?(Hash)
        pointer = pointer[part]
      end

      pointer[last_part]
    end

    # Set the value of the fact.
    #
    # new_value - An object with the new value for the fact
    def value=(new_value)
      set_value(new_value)
    end

    # Set the value of the fact. If the name is specified, this will dig into a structured fact to set
    # the value within the structure.
    #
    # new_value - An object with the new value for the fact
    # name_in   - An optional String to dig into the structure (formatted with :: indicating hash delimiters)
    def set_value(new_value, name_in = nil)
      if name_in.nil?
        if new_value.is_a?(Proc)
          return @value = new_value.call(@value)
        end

        return @value = new_value
      end

      parts = if name_in.is_a?(String)
        name_in.split("::")
      elsif name_in.is_a?(Array)
        name_in.map do |item|
          if item.is_a?(String)
            item
          elsif item.is_a?(Hash) && item.key?("regexp")
            Regexp.new(item["regexp"])
          else
            raise ArgumentError, "Unable to interpret structure item: #{item.inspect}"
          end
        end
      else
        raise ArgumentError, "Unable to interpret structure: #{name_in.inspect}"
      end

      set_structured_value(@value, parts, new_value)
    end

    private

    # Set a value in the data structure of a structured fact. This is intended to be
    # called recursively.
    #
    # subhash - The Hash, part of the fact, being operated upon
    # parts   - The Array to dig in to the hash
    # value   - The value to set the ultimate last part to
    #
    # Does not return anything, but modifies 'subhash'
    def set_structured_value(subhash, parts, value)
      return if subhash.nil?
      raise ArgumentError, "Cannot set structured value at #{parts.first.inspect}" unless subhash.is_a?(Hash)
      raise ArgumentError, "parts must be an Array, got #{parts.inspect}" unless parts.is_a?(Array)

      # At the top level, find all keys that match the first item in the parts.
      matching_keys = subhash.keys.select do |key|
        if parts.first.is_a?(String)
          key == parts.first
        elsif parts.first.is_a?(Regexp)
          parts.first.match(key)
        else
          # :nocov:
          # This is a bug - this code should be unreachable because of the checking in `set_value`
          raise ArgumentError, "part must be a string or regexp, got #{parts.first.inspect}"
          # :nocov:
        end
      end

      # Auto-create a new hash if there is a value, the part is a string, and the key doesn't exist.
      if parts.first.is_a?(String) && !value.nil? && !subhash.key?(parts.first)
        subhash[parts.first] = {}
        matching_keys << parts.first
      end
      return unless matching_keys.any?

      # If we are at the end, set the value or delete the key.
      if parts.size == 1
        if value.nil?
          matching_keys.each { |k| subhash.delete(k) }
        elsif value.is_a?(Proc)
          matching_keys.each do |k|
            new_value = value.call(subhash[k])
            if new_value.nil?
              subhash.delete(k)
            else
              subhash[k] = new_value
            end
          end
        else
          matching_keys.each { |k| subhash[k] = value }
        end
        return
      end

      # We are not at the end. Recurse down to the next level.
      matching_keys.each { |k| set_structured_value(subhash[k], parts[1..-1], value) }
    end
  end
end
