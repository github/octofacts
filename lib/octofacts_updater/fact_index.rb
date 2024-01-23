# frozen_string_literal: true
# This class represents a fact index, which is ultimately represented by a YAML file of
# each index fact, the values seen, and the node(s) containing each value.
#
# fact_one:
#   value_one:
#     - node-1.example.net
#     - node-2.example.net
#   value_three:
#     - node-3.example.net
# fact_two:
#   value_abc:
#     - node-1.example.net
#   value_def:
#     - node-2.example.net
#     - node-3.example.net

require "set"
require "yaml"

module OctofactsUpdater
  class FactIndex
    # We will create a pseudo-fact that simply lists all of the nodes that were considered
    # in the index. Define the name of that pseudo-fact here.
    TOP_LEVEL_NODES_KEY = "_nodes".freeze

    attr_reader :index_data

    # Load an index from the YAML file.
    #
    # filename - A String with the file to be loaded.
    #
    # Returns a OctofactsUpdater::FactIndex object.
    def self.load_file(filename)
      unless File.file?(filename)
        raise Errno::ENOENT, "load_index cannot load #{filename.inspect}"
      end

      data = YAML.safe_load(File.read(filename))
      new(data, filename: filename)
    end

    # Constructor.
    #
    # data     - A Hash of existing index data.
    # filename - Optionally, a String with a file name to write the index to
    def initialize(data = {}, filename: nil)
      @index_data = data
      @filename = filename
    end

    # Add a fact to the index. If the fact already exists in the index, this will overwrite it.
    #
    # fact_name - A String with the name of the fact
    # fixtures  - An Array with fact fixtures (must respond to .facts and .hostname)
    def add(fact_name, fixtures)
      @index_data[fact_name] ||= {}
      fixtures.each do |fixture|
        fact_value = get_fact(fixture, fact_name)
        next if fact_value.nil?
        @index_data[fact_name][fact_value] ||= []
        @index_data[fact_name][fact_value] << fixture.hostname
      end
    end

    # Get a list of all of the nodes in the index. This supports a quick mode (default) where the
    # TOP_LEVEL_NODES_KEY key is used, and a more detailed mode where this digs through each indexed
    # fact and value to build a list of nodes.
    #
    # quick_mode - Boolean whether to use quick mode (default=true)
    #
    # Returns an Array of nodes whose facts are indexed.
    def nodes(quick_mode = true)
      if quick_mode && @index_data.key?(TOP_LEVEL_NODES_KEY)
        return @index_data[TOP_LEVEL_NODES_KEY]
      end

      seen_hosts = Set.new
      @index_data.each do |fact_name, fact_values|
        next if fact_name == TOP_LEVEL_NODES_KEY
        fact_values.each do |_fact_value, nodes|
          seen_hosts.merge(nodes)
        end
      end
      seen_hosts.to_a.sort
    end

    # Rebuild an index with a specified list of facts. This will remove any indexed facts that
    # are not on the list of facts to use.
    #
    # facts_to_index - An Array of Strings with facts to index
    # fixtures       - An Array with fact fixtures (must respond to .facts and .hostname)
    def reindex(facts_to_index, fixtures)
      @index_data = {}
      facts_to_index.each { |fact| add(fact, fixtures) }
      set_top_level_nodes_fact(fixtures)
    end

    # Create the top level nodes pseudo-fact.
    #
    # fixtures - An Array with fact fixtures (must respond to .hostname)
    def set_top_level_nodes_fact(fixtures)
      @index_data[TOP_LEVEL_NODES_KEY] = fixtures.map { |f| f.hostname }.sort
    end

    # Get YAML representation of the index.
    # This sorts the hash and any arrays without modifying the object.
    def to_yaml
      YAML.dump(recursive_sort(index_data))
    end

    def recursive_sort(object_in)
      if object_in.is_a?(Hash)
        object_out = {}
        object_in.keys.sort.each { |k| object_out[k] = recursive_sort(object_in[k]) }
        object_out
      elsif object_in.is_a?(Array)
        object_in.sort.map { |v| recursive_sort(v) }
      else
        object_in
      end
    end

    # Write the fact index out to a YAML file.
    #
    # filename - A String with the file to write (defaults to filename from constructor if available)
    def write_file(filename = nil)
      filename ||= @filename
      unless filename.is_a?(String)
        raise ArgumentError, "Called write_file() for fact_index without a filename"
      end
      File.open(filename, "w") { |f| f.write(to_yaml) }
    end

    private

    # Extract a (possibly) structured fact.
    #
    # fixture   - Fact fixture, must respond to .facts
    # fact_name - A String with the name of the fact
    #
    # Returns the value of the fact, or nil if fact or structure does not exist.
    def get_fact(fixture, fact_name)
      pointer = fixture.facts

      # Get the fact of interest from the fixture, whether structured or not.
      components = fact_name.split(".")
      first_component = components.shift
      return unless pointer.key?(first_component)

      # For simple non-structured facts, just return the value.
      return pointer[first_component].value if components.empty?

      # Structured facts: dig into the structure.
      pointer = pointer[first_component].value
      last_component = components.pop
      components.each do |part|
        return unless pointer.key?(part)
        return unless pointer[part].is_a?(Hash)
        pointer = pointer[part]
      end
      pointer[last_component]
    end
  end
end
