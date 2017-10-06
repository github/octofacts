require_relative "base"

module Octofacts
  class Manipulators
    class Replace < Octofacts::Manipulators
      # Public: Executor for the .replace command.
      #
      # Sets the fact to the specified value. If the fact didn't exist before, it's created.
      #
      # facts - Hash of current facts
      # args  - Arguments, here consisting of an array of hashes with replacement parameters
      def self.execute(facts, *args, &_block)
        args.each do |arg|
          raise ArgumentError, "Must pass a hash of target facts to .replace - got #{arg}" unless arg.is_a?(Hash)
          arg.each { |key, val| set(facts, key, val) }
        end
      end
    end
  end
end
