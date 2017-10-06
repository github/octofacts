module Octofacts
  class Spec
    def self.fixture_root
      File.expand_path("../fixtures", File.dirname(__FILE__))
    end
  end

  module Backends
    class Hash < Base
      attr_reader :facts, :select_called, :reject_called, :prefer_called

      def initialize(hash_in)
        @facts = hash_in
      end

      def select(_)
        @select_called = true
        self
      end

      def reject(_)
        @reject_called = true
        self
      end

      def prefer(_)
        @prefer_called = true
        self
      end
    end
  end

  class Manipulators
    class Fake < Octofacts::Manipulators
      def self.execute(facts, *args)
        # noop
      end
    end
  end
end
