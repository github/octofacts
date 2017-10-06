require "yaml"
require "set"

module Octofacts
  module Backends
    class Index < Base
      attr_reader :index_path, :fixture_path, :options
      attr_writer :facts
      attr_accessor :nodes

      def initialize(args = {})
        index_path = Octofacts::Util::Config.fetch(:octofacts_index_path, args)
        fixture_path = Octofacts::Util::Config.fetch(:octofacts_fixture_path, args)
        strict_index = Octofacts::Util::Config.fetch(:octofacts_strict_index, args, false)

        raise(ArgumentError, "No index passed and ENV['OCTOFACTS_INDEX_PATH'] is not defined") if index_path.nil?
        raise(ArgumentError, "No fixture path passed and ENV['OCTOFACTS_FIXTURE_PATH'] is not defined") if fixture_path.nil?
        raise(Errno::ENOENT, "The index file #{index_path} does not exist") unless File.file?(index_path)
        raise(Errno::ENOENT, "The fixture path #{fixture_path} does not exist") unless File.directory?(fixture_path)

        @index_path = index_path
        @fixture_path = fixture_path
        @strict_index = strict_index == true || strict_index == "true"
        @facts = nil
        @options = args

        @node_facts = {}

        # If there are any other arguments treat them as `select` conditions.
        remaining_args = args.dup
        remaining_args.delete(:octofacts_index_path)
        remaining_args.delete(:octofacts_fixture_path)
        remaining_args.delete(:octofacts_strict_index)
        select(remaining_args) if remaining_args
      end

      def facts
        @facts ||= node_facts(nodes.first)
      end

      def select(conditions)
        Octofacts::Util::Keys.desymbolize_keys!(conditions)
        conditions.each do |key, value|
          add_fact_to_index(key) unless indexed_fact?(key)
          matching_nodes = index[key][value.to_s]
          raise Octofacts::Errors::NoFactsError if matching_nodes.nil?
          self.nodes = nodes & matching_nodes
        end

        self
      end

      def reject(conditions)
        matching_nodes = nodes
        Octofacts::Util::Keys.desymbolize_keys!(conditions)
        conditions.each do |key, value|
          add_fact_to_index(key) unless indexed_fact?(key)
          unless index[key][value.to_s].nil?
            matching_nodes -= index[key][value.to_s]
            raise Octofacts::Errors::NoFactsError if matching_nodes.empty?
          end
        end

        self.nodes = matching_nodes
        self
      end

      def prefer(conditions)
        Octofacts::Util::Keys.desymbolize_keys!(conditions)
        conditions.each do |key, value|
          add_fact_to_index(key) unless indexed_fact?(key)
          matching_nodes = index[key][value.to_s]
          unless matching_nodes.nil?
            self.nodes = (matching_nodes.to_set + nodes.to_set).to_a
          end
        end

        self
      end

      private

      # If a select/reject/prefer is called and the fact is not in the index, this will
      # load the fact files for all currently eligible nodes and then add the fact to the
      # in-memory index. This can be memory-intensive and time-intensive depending on the
      # number of fact fixtures, so it is possible to disable this by passing
      # `:strict_index => true` to the backend constructor, or by setting
      # ENV["OCTOFACTS_STRICT_INDEX"] = "true" in the environment.
      def add_fact_to_index(fact)
        if @strict_index || ENV["OCTOFACTS_STRICT_INDEX"] == "true"
          raise Octofacts::Errors::FactNotIndexed, "Fact #{fact} is not indexed and strict indexing is enabled."
        end

        index[fact] ||= {}
        nodes.each do |node|
          v = node_facts(node)[fact]
          if v.nil?
            # TODO: Index this somehow
          else
            index[fact][v.to_s] ||= []
            index[fact][v.to_s] << node
          end
        end
      end

      def nodes
        @nodes ||= index["_nodes"]
      end

      def index
        @index ||= YAML.safe_load(File.read(index_path))
      end

      def indexed_fact?(fact)
        index.key?(fact)
      end

      def node_facts(node)
        @node_facts[node] ||= begin
          f = YAML.safe_load(File.read("#{fixture_path}/#{node}.yaml"))
          Octofacts::Util::Keys.desymbolize_keys!(f)
          f
        end
      end
    end
  end
end
