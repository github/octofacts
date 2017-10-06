# Retrieves configuration parameters from:
#   - input hash
#   - rspec configuration
#   - environment
module Octofacts
  module Util
    class Config
      # Fetch a variable from various sources
      def self.fetch(variable_name, hash_in = {}, default = nil)
        if hash_in.key?(variable_name)
          return hash_in[variable_name]
        end

        begin
          rspec_value = RSpec.configuration.send(variable_name)
          return rspec_value if rspec_value
        rescue NoMethodError
          # Just skip if undefined
        end

        env_key = variable_name.to_s.upcase
        return ENV[env_key] if ENV.key?(env_key)

        default
      end
    end
  end
end
