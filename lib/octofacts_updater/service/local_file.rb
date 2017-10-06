# This class reads a YAML file from the local file system so that it can be used as a source
# in octofacts-updater. This was originally intended for a quickstart tutorial, since it requires
# no real configuration. However it could also be used in production, if the user wants to create
# their own fact obtaining logic outside of octofacts-updater and simply feed in the results.

require_relative "base"

module OctofactsUpdater
  module Service
    class LocalFile < OctofactsUpdater::Service::Base
      # Get the facts from a local file, without using PuppetDB, SSH, or any of the other automated methods.
      #
      # node   - A String with the FQDN for which to retrieve facts
      # config - A Hash with configuration settings
      #
      # Returns a Hash with the facts.
      def self.facts(node, config = {})
        unless config["localfile"].is_a?(Hash)
          raise ArgumentError, "OctofactsUpdater::Service::LocalFile requires localfile section"
        end
        config_localfile = config["localfile"].dup

        path_raw = config_localfile.delete("path")
        unless path_raw
          raise ArgumentError, "OctofactsUpdater::Service::LocalFile requires 'path' in the localfile section"
        end
        path = path_raw.gsub("%%NODE%%", node)
        unless File.file?(path)
          raise Errno::ENOENT, "OctofactsUpdater::Service::LocalFile cannot find a file at #{path.inspect}"
        end

        parse_yaml(File.read(path))
      end
    end
  end
end
