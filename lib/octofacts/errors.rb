module Octofacts
  class Errors
    class FactNotIndexed < RuntimeError; end
    class OperationNotPermitted < RuntimeError; end
    class NoFactsError < RuntimeError; end
  end
end
