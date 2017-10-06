# This class contains methods to interact with an external node classifier.

require "open3"
require "shellwords"
require "yaml"

module OctofactsUpdater
  module Service
    class ENC
      # Execute the external node classifier script. This expects the value of "path" to be
      # set in the configuration.
      #
      # hostname - A String with the FQDN of the host.
      # config   - A Hash with configuration data.
      #
      # Returns a Hash consisting of the parsed output of the ENC.
      def self.run_enc(hostname, config)
        unless config["enc"].is_a?(Hash)
          raise ArgumentError, "The ENC configuration must be defined"
        end

        unless config["enc"]["path"].is_a?(String)
          raise ArgumentError, "The ENC path must be defined"
        end

        unless File.file?(config["enc"]["path"])
          raise Errno::ENOENT, "The ENC script could not be found at #{config['enc']['path'].inspect}"
        end

        command = [config["enc"]["path"], hostname].map { |x| Shellwords.escape(x) }.join(" ")
        stdout, stderr, exitstatus = Open3.capture3(command)
        unless exitstatus.exitstatus == 0
          output = { "stdout" => stdout, "stderr" => stderr, "exitstatus" => exitstatus.exitstatus }
          raise "Error executing #{command.inspect}: #{output.to_yaml}"
        end

        YAML.load(stdout)
      end
    end
  end
end
