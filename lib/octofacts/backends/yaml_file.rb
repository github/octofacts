# frozen_literal_string: true
#
require "yaml"

module Octofacts
  module Backends
    class YamlFile < Base
      attr_reader :filename, :options

      def initialize(filename, options = {})
        raise(Errno::ENOENT, "The file #{filename} does not exist") unless File.file?(filename)

        @filename = filename
        @options  = options
        @facts    = nil
      end

      def facts
        @facts ||= begin
          f = YAML.safe_load(File.read(filename))
          Octofacts::Util::Keys.symbolize_keys!(f)
          f
        end
      end

      def select(conditions)
        Octofacts::Util::Keys.symbolize_keys!(conditions)
        raise Octofacts::Errors::NoFactsError unless (conditions.to_a - facts.to_a).empty?
      end

      def reject(conditions)
        Octofacts::Util::Keys.symbolize_keys!(conditions)
        raise Octofacts::Errors::NoFactsError if (conditions.to_a - facts.to_a).empty?
      end

      def prefer(conditions)
        # noop
      end
    end
  end
end
