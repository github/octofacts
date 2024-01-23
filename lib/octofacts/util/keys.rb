# frozen_string_literal: true
module Octofacts
  module Util
    class Keys
      # Downcase all keys.
      #
      # rspec-puppet does this internally, but depending on how Octofacts is called, this logic may not
      # be triggered. Therefore, we downcase all keys ourselves.
      def self.downcase_keys!(input)
        raise ArgumentError, "downcase_keys! expects Hash, not #{input.class}" unless input.is_a?(Hash)

        input_keys = input.keys.dup
        input_keys.each do |k|
          downcase_keys!(input[k]) if input[k].is_a?(Hash)
          next if k.to_s == k.to_s.downcase
          new_key = k.is_a?(Symbol) ? k.to_s.downcase.to_sym : k.downcase
          input[new_key] = input.delete(k)
        end
        input
      end

      # Symbolize all keys.
      #
      # Many people work with symbolized keys rather than string keys when dealing with fact fixtures.
      # This method recursively converts all keys to symbols.
      def self.symbolize_keys!(input)
        raise ArgumentError, "symbolize_keys! expects Hash, not #{input.class}" unless input.is_a?(Hash)

        input_keys = input.keys.dup
        input_keys.each do |k|
          symbolize_keys!(input[k]) if input[k].is_a?(Hash)
          input[k.to_sym] = input.delete(k) unless k.is_a?(Symbol)
        end
        input
      end

      # De-symbolize all keys.
      #
      # rspec-puppet ultimately wants stringified keys, so this is a method to turn symbols back into strings.
      def self.desymbolize_keys!(input)
        raise ArgumentError, "desymbolize_keys! expects Hash, not #{input.class}" unless input.is_a?(Hash)

        input_keys = input.keys.dup
        input_keys.each do |k|
          desymbolize_keys!(input[k]) if input[k].is_a?(Hash)
          input[k.to_s] = input.delete(k) unless k.is_a?(String)
        end
        input
      end
    end
  end
end
