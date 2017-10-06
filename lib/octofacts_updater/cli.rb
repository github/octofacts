# :nocov:
require "optparse"

module OctofactsUpdater
  class CLI
    # Constructor.
    #
    # argv - The Array with command line arguments.
    def initialize(argv)
      @opts = {}
      OptionParser.new(argv) do |opts|
        opts.banner = "Usage: octofacts-updater [options]"

        opts.on("-a", "--action <action>", String, "Action to take") do |a|
          @opts[:action] = a
        end

        opts.on("-c", "--config <config_file>", String, "Path to configuration file") do |f|
          raise "Invalid configuration file" unless File.file?(f)
          @opts[:config] = f
        end

        opts.on("-H", "--hostname <hostname>", String, "FQDN of the host whose facts are to be gathered") do |h|
          @opts[:hostname] = h
        end

        opts.on("-o", "--output-file <filename>", String, "Path to output file to write") do |i|
          @opts[:output_file] = i
        end

        opts.on("-l", "--list <host1,host2,...>", Array, "List of hosts to update or index") do |l|
          @opts[:host_list] = l
        end

        opts.on("--[no-]quick", "Quick indexing: Use existing YAML fact fixtures when available") do |q|
          @opts[:quick] = q
        end

        opts.on("-p", "--path <directory>", "Path where to read/write host fixtures when working in bulk") do |path|
          @opts[:path] = path
        end

        opts.on("--github", "Push any changes to a branch on GitHub (requires --action=bulk)") do
          @opts[:github] ||= {}
          @opts[:github][:enabled] = true
        end

        opts.on("--datasource <datasource>", "Specify the data source to use when retrieving facts (localfile, puppetdb, ssh)") do |ds|
          unless %w{localfile puppetdb ssh}.include?(ds)
            raise ArgumentError, "Invalid datasource #{ds.inspect}. Acceptable values: localfile, puppetdb, ssh."
          end
          @opts[:datasource] = ds.to_sym
        end

        opts.on("--config-override <section:key=value>", Array, "Override a portion of the configuration") do |co_array|
          co_array.each do |co|
            if co =~ /\A(\w+):(\S+?)=(.+?)\z/
              @opts[Regexp.last_match(1).to_sym] ||= {}
              @opts[Regexp.last_match(1).to_sym][Regexp.last_match(2).to_sym] = Regexp.last_match(3)
            else
              raise ArgumentError, "Malformed argument: --config-override must be in the format section:key=value"
            end
          end
        end
      end.parse!
      validate_cli
    end

    def usage
      puts "Usage: octofacts-updater --action <action> [--config-file /path/to/config.yaml] [other options]"
      puts ""
      puts "Available actions:"
      puts "  bulk:  Update fixtures and index in bulk"
      puts "  facts: Obtain facts for one node (requires --hostname <hostname>)"
      puts ""
    end

    # Run method. Call this to run the octofacts updater with the object that was
    # previously construcuted.
    def run
      unless opts[:action]
        usage
        exit 255
      end

      @config = {}

      if opts[:config]
        @config = YAML.load_file(opts[:config])
        substitute_relative_paths!(@config, File.dirname(opts[:config]))
        load_plugins(@config["plugins"]) if @config.key?("plugins")
      end

      @config[:options] = {}
      opts.each do |k, v|
        if v.is_a?(Hash)
          @config[k.to_s] ||= {}
          v.each do |v_key, v_val|
            @config[k.to_s][v_key.to_s] = v_val
            @config[k.to_s].delete(v_key.to_s) if v_val.nil?
          end
        else
          @config[:options][k] = v
        end
      end

      return handle_action_bulk if opts[:action] == "bulk"
      return handle_action_facts if opts[:action] == "facts"

      usage
      exit 255
    end

    def substitute_relative_paths!(object_in, basedir)
      if object_in.is_a?(Hash)
        object_in.each { |k, v| object_in[k] = substitute_relative_paths!(v, basedir) }
      elsif object_in.is_a?(Array)
        object_in.map! { |v| substitute_relative_paths!(v, basedir) }
      elsif object_in.is_a?(String)
        if object_in =~ %r{^\.\.?(/|\z)}
          object_in = File.expand_path(object_in, basedir)
        end
        object_in
      else
        object_in
      end
    end

    def handle_action_bulk
      facts_to_index = @config.fetch("index", {})["indexed_facts"]
      unless facts_to_index.is_a?(Array)
        raise ArgumentError, "Must declare index:indexed_facts in configuration to use bulk update"
      end

      nodes = if opts[:host_list]
        opts[:host_list]
      elsif opts[:hostname]
        [opts[:hostname]]
      else
        OctofactsUpdater::FactIndex.load_file(index_file).nodes(true)
      end
      if nodes.empty?
        raise ArgumentError, "Cannot run bulk update with no nodes to check"
      end

      path = opts[:path] || @config.fetch("index", {})["node_path"]
      paths = []

      fixtures = nodes.map do |hostname|
        if opts[:quick] && path && File.file?(File.join(path, "#{hostname}.yaml"))
          OctofactsUpdater::Fixture.load_file(hostname, File.join(path, "#{hostname}.yaml"))
        else
          fixture = OctofactsUpdater::Fixture.make(hostname, @config)
          if path && File.directory?(path)
            fixture.write_file(File.join(path, "#{hostname}.yaml"))
            paths << File.join(path, "#{hostname}.yaml")
          end
          fixture
        end
      end

      index = OctofactsUpdater::FactIndex.load_file(index_file)
      index.reindex(facts_to_index, fixtures)
      index.write_file
      paths << index_file

      if opts[:github] && opts[:github][:enabled]
        OctofactsUpdater::Service::GitHub.run(config["github"]["base_directory"], paths, @config)
      end
    end

    def handle_action_facts
      unless opts[:hostname]
        raise ArgumentError, "--hostname <hostname> must be specified to use --action facts"
      end

      facts_for_one_node
    end

    private

    attr_reader :config, :opts

    # Determine the facts for one node and print to the console or write to the specified file.
    def facts_for_one_node
      fixture = OctofactsUpdater::Fixture.make(opts[:hostname], @config)
      print_or_write(fixture.to_yaml)
    end

    # Get the index file from the options or configuration file. Raise error if it does not exist or
    # was not specified.
    def index_file
      @index_file ||= begin
        if config.fetch("index", {})["file"]
          return config["index"]["file"] if File.file?(config["index"]["file"])
          raise Errno::ENOENT, "Index file (#{config['index']['file'].inspect}) does not exist"
        end
        raise ArgumentError, "No index file specified on command line (--index-file) or in configuration file"
      end
    end

    # Load plugins as per configuration file. Note: all plugins embedded in this gem are automatically
    # loaded. This is just for user-specified plugins.
    #
    # plugins - An Array of file names to load
    def load_plugins(plugins)
      unless plugins.is_a?(Array)
        raise ArgumentError, "load_plugins expects an array, got #{plugins.inspect}"
      end

      plugins.each do |plugin|
        plugin_file = plugin.start_with?("/") ? plugin : File.expand_path("../../#{plugin}", File.dirname(__FILE__))
        unless File.file?(plugin_file)
          raise Errno::ENOENT, "Failed to find plugin #{plugin.inspect} at #{plugin_file}"
        end
        require plugin_file
      end
    end

    # Print or write to file depending on whether or not the output file was set.
    #
    # data - Data to print or write.
    def print_or_write(data)
      if opts[:output_file]
        File.open(opts[:output_file], "w") { |f| f.write(data) }
      else
        puts data
      end
    end

    # Validate command line options. Kick out invalid combinations of options immediately.
    def validate_cli
      if opts[:path] && !File.directory?(opts[:path])
        raise Errno::ENOENT, "An existing directory must be specified with -p/--path"
      end
    end
  end
end
# :nocov:
