# frozen_string_literal: true
#
require "yaml"

module Octofacts
  class Facts
    attr_writer :facts

    # Constructor.
    #
    # backend - An Octofacts::Backends object (preferred)
    # options - Additional options (e.g., downcase keys, symbolize keys, etc.)
    def initialize(args = {})
      @backend = args.fetch(:backend)
      @facts_manipulated = false

      options = args.fetch(:options, {})
      @downcase_keys = args.fetch(:downcase_keys, options.fetch(:downcase_keys, true))
    end

    # To hash. (This method is intended to be called by rspec-puppet.)
    #
    # This loads the fact file and downcases, desymbolizes, and otherwise manipulates the keys.
    # The output is suitable for consumption by rspec-puppet.
    def to_hash
      f = facts
      downcase_keys!(f) if @downcase_keys
      desymbolize_keys!(f)
      f
    end
    alias_method :to_h, :to_hash

    # To fact hash. (This method is intended to be called by developers.)
    #
    # This loads the fact file and downcases, symbolizes, and otherwise manipulates the keys.
    # This is very similar to 'to_hash' except that it returns symbolized keys.
    # The output is suitable for consumption by rspec-puppet (note that rspec-puppet will
    # de-symbolize all the keys in the hash object though).
    def facts
      @facts ||= begin
        f = @backend.facts
        downcase_keys!(f) if @downcase_keys
        symbolize_keys!(f)
        f
      end
    end

    # Calls to backend methods.
    #
    # These calls are passed through directly to backend methods.
    def select(*args)
      if @facts_manipulated
        raise Octofacts::Errors::OperationNotPermitted, "Cannot call select() after backend facts have been manipulated"
      end
      @backend.select(*args)
      self
    end

    def reject(*args)
      if @facts_manipulated
        raise Octofacts::Errors::OperationNotPermitted, "Cannot call reject() after backend facts have been manipulated"
      end
      @backend.reject(*args)
      self
    end

    def prefer(*args)
      if @facts_manipulated
        raise Octofacts::Errors::OperationNotPermitted, "Cannot call prefer() after backend facts have been manipulated"
      end
      @backend.prefer(*args)
      self
    end

    # Missing method - this is used to dispatch to manipulators or to call a Hash method in the facts.
    #
    # Try calling a Manipulator method, delegate to the facts hash or else error out.
    #
    # Returns this object (so that calls to manipulators can be chained).
    def method_missing(name, *args, &block)
      if Octofacts::Manipulators.run(self, name, *args, &block)
        @facts_manipulated = true
        return self
      end

      if facts.respond_to?(name, false)
        if args[0].is_a?(String) || args[0].is_a?(Symbol)
          args[0] = string_or_symbolized_key(args[0])
        end
        return facts.send(name, *args)
      end

      raise NameError, "Unknown method '#{name}' in #{self.class}"
    end

    def respond_to?(method, include_all = false)
      camelized_name = (method.to_s).split("_").collect(&:capitalize).join
      super || Kernel.const_get("Octofacts::Manipulators::#{camelized_name}")
    rescue NameError
      return facts.respond_to?(method, include_all)
    end

    private

    def downcase_keys!(input)
      Octofacts::Util::Keys.downcase_keys!(input)
    end

    def symbolize_keys!(input)
      Octofacts::Util::Keys.symbolize_keys!(input)
    end

    def desymbolize_keys!(input)
      Octofacts::Util::Keys.desymbolize_keys!(input)
    end

    def string_or_symbolized_key(input)
      return input.to_s if facts.key?(input.to_s)
      return input.to_sym if facts.key?(input.to_sym)
      input
    end
  end
end
