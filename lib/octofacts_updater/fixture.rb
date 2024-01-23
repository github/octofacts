# frozen_string_literal: true
# This class represents a fact fixture, which is a set of facts along with a node name.
# Facts are OctofactsUpdater::Fact objects, and internally are stored as a hash table
# with the key being the fact name and the value being the OctofactsUpdater::Fact object.

require "yaml"

module OctofactsUpdater
  class Fixture
    attr_reader :facts, :hostname

    # Make a fact fixture for the specified host name by consulting data sources
    # specified in the configuration.
    #
    # hostname - A String with the FQDN of the host.
    # config   - A Hash with configuration data.
    #
    # Returns the OctofactsUpdater::Fixture object.
    def self.make(hostname, config)
      fact_hash = facts_from_configured_datasource(hostname, config)

      if config.key?("enc")
        enc_data = OctofactsUpdater::Service::ENC.run_enc(hostname, config)
        if enc_data.key?("parameters")
          fact_hash.merge! enc_data["parameters"]
        end
      end

      obj = new(hostname, config, fact_hash)
      obj.execute_plugins!
    end

    # Get fact hash from the first configured and working data source.
    #
    # hostname - A String with the FQDN of the host.
    # config   - A Hash with configuration data.
    #
    # Returns a Hash with the facts for the specified node; raises exception if this was not possible.
    def self.facts_from_configured_datasource(hostname, config)
      last_exception = nil
      data_sources = %w(LocalFile PuppetDB SSH)
      data_sources.each do |ds|
        next if config.fetch(:options, {})[:datasource] && config[:options][:datasource] != ds.downcase.to_sym
        next unless config.key?(ds.downcase)
        clazz = Kernel.const_get("OctofactsUpdater::Service::#{ds}")
        begin
          result = clazz.send(:facts, hostname, config)
          return result["values"] if result["values"].is_a?(Hash)
          return result
        rescue => e
          last_exception = e
        end
      end

      raise last_exception if last_exception
      raise ArgumentError, "No fact data sources were configured"
    end

    # Load a fact fixture from a file. This helps create an index without the more expensive operation
    # of actually looking up the facts from the data source.
    #
    # hostname - A String with the FQDN of the host.
    # filename - A String with the filename of the existing host.
    #
    # Returns the OctofactsUpdater::Fixture object.
    def self.load_file(hostname, filename)
      unless File.file?(filename)
        raise Errno::ENOENT, "Could not load facts from #{filename} because it does not exist"
      end

      data = YAML.safe_load(File.read(filename))
      new(hostname, {}, data)
    end

    # Constructor.
    #
    # hostname  - A String with the FQDN of the host.
    # config    - A Hash with configuration data.
    # fact_hash - A Hash with the facts (key = fact name, value = fact value).
    def initialize(hostname, config, fact_hash = {})
      @hostname = hostname
      @config = config
      @facts = Hash[fact_hash.collect { |k, v| [k, OctofactsUpdater::Fact.new(k, v)] }]
    end

    # Execute plugins to clean up facts as per configuration. This modifies the value of the facts
    # stored in this object. Any facts with a value of nil are removed.
    #
    # Returns a copy of this object.
    def execute_plugins!
      return self unless @config["facts"].is_a?(Hash)

      @config["facts"].each do |fact_tag, args|
        fact_names(fact_tag, args).each do |fact_name|
          @facts[fact_name] ||= OctofactsUpdater::Fact.new(fact_name, nil)
          plugin_name = args.fetch("plugin", "noop")
          OctofactsUpdater::Plugin.execute(plugin_name, @facts[fact_name], args, @facts)
          @facts.delete(fact_name) if @facts[fact_name].value.nil?
        end
      end

      self
    end

    # Get fact names associated with a particular data structure. Implements:
    # - Default behavior, where YAML key = fact name
    # - Regexp behavior, where YAML "regexp" key is used to match against all facts
    # - Override behavior, where YAML "fact" key overrides whatever is in the tag
    #
    # fact_tag - A String with the YAML key
    # args     - A Hash with the arguments
    #
    # Returns an Array of Strings with all fact names matched.
    def fact_names(fact_tag, args = {})
      return [args["fact"]] if args.key?("fact")
      return [fact_tag] unless args.key?("regexp")
      rexp = Regexp.new(args["regexp"])
      @facts.keys.select { |k| rexp.match(k) }
    end

    # Write this fixture to a file.
    #
    # filename - A String with the filename to write.
    def write_file(filename)
      File.open(filename, "w") { |f| f.write(to_yaml) }
    end

    # YAML representation of the fact fixture.
    #
    # Returns a String containing the YAML representation of the fact fixture.
    def to_yaml
      sorted_facts = @facts.sort.to_h
      facts_hash_with_expanded_values = Hash[sorted_facts.collect { |k, v| [k, v.value] }]
      YAML.dump(facts_hash_with_expanded_values)
    end
  end
end
