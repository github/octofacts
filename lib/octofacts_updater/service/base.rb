# This contains handy utility methods that might be used in any of the other classes.

require "yaml"

module OctofactsUpdater
  module Service
    class Base
      # Parse a YAML fact file from PuppetServer. This removes the header (e.g. "--- !ruby/object:Puppet::Node::Facts")
      # so that it's not necessary to bring in all of Puppet.
      #
      # yaml_string - A String with YAML to parse.
      #
      # Returns a Hash with the facts.
      def self.parse_yaml(yaml_string)
        # Convert first "---" after any comments and blank lines.
        yaml_array = yaml_string.to_s.split("\n")
        yaml_array.each_with_index do |line, index|
          next if line =~ /\A\s*#/
          next if line.strip == ""
          if line.start_with?("---")
            yaml_array[index] = "---"
          end
          break
        end

        # Parse the YAML file
        result = YAML.safe_load(yaml_array.join("\n"))

        # Pull out "values" if this is in a name-values format. Otherwise just return the hash.
        return result["values"] if result["values"].is_a?(Hash)
        result
      end
    end
  end
end
