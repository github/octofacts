# This class provides the base methods for fact manipulation plugins.

require "digest"

module OctofactsUpdater
  class Plugin
    # Register a plugin.
    #
    # plugin_name - A Symbol which is the name of the plugin.
    # block       - A block of code that constitutes the plugin. See sample plugins for expected format.
    def self.register(plugin_name, &block)
      @plugins ||= {}
      if @plugins.key?(plugin_name.to_sym)
        raise ArgumentError, "A plugin named #{plugin_name} is already registered."
      end
      @plugins[plugin_name.to_sym] = block
    end

    # Execute a plugin
    #
    # plugin_name - A Symbol which is the name of the plugin.
    # fact        - An OctofactsUpdater::Fact object
    # args        - An optional Hash of additional configuration arguments
    # all_facts   - A Hash of all of the facts
    #
    # Returns nothing, but may adjust the "fact"
    def self.execute(plugin_name, fact, args = {}, all_facts = {})
      unless @plugins.key?(plugin_name.to_sym)
        raise NoMethodError, "A plugin named #{plugin_name} could not be found."
      end

      begin
        @plugins[plugin_name.to_sym].call(fact, args, all_facts)
      rescue => e
        warn "#{e.class} occurred executing #{plugin_name} on #{fact.name} with value #{fact.value.inspect}"
        raise e
      end
    end

    # Clear out a plugin definition. (Useful for testing.)
    #
    # plugin_name - The name of the plugin to clear.
    def self.clear!(plugin_name)
      @plugins ||= {}
      @plugins.delete(plugin_name.to_sym)
    end

    # Get the plugins hash.
    def self.plugins
      @plugins
    end

    # ---------------------------
    # Below this point are shared methods intended to be called by plugins.
    # ---------------------------

    # Randomize a long string. This method accepts a string (consisting of, for example, a SSH key)
    # and returns a string of the same length, but with randomized characters.
    #
    # string_in - A String with the original fact value.
    #
    # Returns a String with the same length as string_in.
    def self.randomize_long_string(string_in)
      seed = Digest::MD5.hexdigest(string_in).to_i(36)
      prng = Random.new(seed)
      chars = [("a".."z"), ("A".."Z"), ("0".."9")].flat_map(&:to_a)
      (1..(string_in.length)).map { chars[prng.rand(chars.length)] }.join
    end
  end
end
