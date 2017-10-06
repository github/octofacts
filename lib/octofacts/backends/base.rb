module Octofacts
  module Backends
    # This is a template class to define the minimum API to be implemented
    class Base
      # Returns a hash of the facts selected based on current criteria. Once this is done,
      # it is no longer possible to select, reject, or prefer.
      def facts
        # :nocov:
        raise NotImplementedError, "This method needs to be implemented in the subclass"
        # :nocov:
      end

      # Filters the possible fact sets based on the criteria.
      def select(*)
        # :nocov:
        raise NotImplementedError, "This method needs to be implemented in the subclass"
        # :nocov:
      end

      # Removes possible fact sets based on the criteria.
      def reject(*)
        # :nocov:
        raise NotImplementedError, "This method needs to be implemented in the subclass"
        # :nocov:
      end

      # Reorders possible fact sets based on the criteria.
      def prefer(*)
        # :nocov:
        raise NotImplementedError, "This method needs to be implemented in the subclass"
        # :nocov:
      end
    end
  end
end
