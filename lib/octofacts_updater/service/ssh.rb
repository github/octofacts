# frozen_string_literal: true
# This class interacts with a puppetserver to obtain facts from that server's YAML cache.
# This is achieved by SSH-ing to the server and obtaining the fact file directly from the
# puppetserver's cache. This can also be used to SSH to an actual node and run a command,
# e.g. `facter -p --yaml` to grab actual facts from a running production node.

require "net/ssh"
require "shellwords"

require_relative "base"

module OctofactsUpdater
  module Service
    class SSH < OctofactsUpdater::Service::Base
      CACHE_DIR = "/opt/puppetlabs/server/data/puppetserver/yaml/facts"
      COMMAND = "cat %%NODE%%.yaml"

      # Get the facts for a specific node.
      #
      # node   - A String with the FQDN for which to retrieve facts
      # config - A Hash with configuration settings
      #
      # Returns a Hash with the facts.
      def self.facts(node, config = {})
        unless config["ssh"].is_a?(Hash)
          raise ArgumentError, "OctofactsUpdater::Service::SSH requires ssh section"
        end
        config_ssh = config["ssh"].dup

        server_raw = config_ssh.delete("server")
        unless server_raw
          raise ArgumentError, "OctofactsUpdater::Service::SSH requires 'server' in the ssh section"
        end
        server = server_raw.gsub("%%NODE%%", node)

        user = config_ssh.delete("user") || ENV["USER"]
        unless user
          raise ArgumentError, "OctofactsUpdater::Service::SSH requires 'user' in the ssh section"
        end

        # Default is to 'cd (puppetserver cache dir) && cat (node).yaml' but this can
        # be overridden by specifying a command in the SSH options. "%%NODE%%" will always
        # be replaced by the FQDN of the node in the overall result.
        cache_dir = config_ssh.delete("cache_dir") || CACHE_DIR
        command_raw = config_ssh.delete("command") || "cd #{Shellwords.escape(cache_dir)} && #{COMMAND}"
        command = command_raw.gsub("%%NODE%%", node)

        # Everything left over in config["ssh"] (once server, user, command, and cache_dir are removed) is
        # symbolized and passed directory to Net::SSH.
        net_ssh_opts = config_ssh.map { |k, v| [k.to_sym, v] }.to_h || {}
        ret = Net::SSH.start(server, user, net_ssh_opts) do |ssh|
          ssh.exec! command
        end
        return { "name" => node, "values" => parse_yaml(ret.to_s.strip) } if ret.exitstatus == 0
        raise "ssh failed with exitcode=#{ret.exitstatus}: #{ret.to_s.strip}"
      end
    end
  end
end
