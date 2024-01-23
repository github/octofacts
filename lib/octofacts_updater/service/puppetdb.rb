# frozen_string_literal: true
# This class interacts with puppetdb to pull the facts from the recent
# run of Puppet on a given node. This uses octocatalog-diff on the back end to
# pull the facts from puppetdb.

require "octocatalog-diff"

module OctofactsUpdater
  module Service
    class PuppetDB
      # Get the facts for a specific node.
      #
      # node   - A String with the FQDN for which to retrieve facts
      # config - An optional Hash with configuration settings
      #
      # Returns a Hash with the facts (via octocatalog-diff)
      def self.facts(node, config = {})
        fact_obj = OctocatalogDiff::Facts.new(
          node: node.strip,
          backend: :puppetdb,
          puppetdb_url: puppetdb_url(config)
        )
        facts = fact_obj.facts(node)
        return facts unless facts.nil?
        raise OctocatalogDiff::Errors::FactSourceError, "Fact retrieval failed for #{node}"
      end

      # Get the puppetdb URL from the configuration or environment.
      #
      # config - An optional Hash with configuration settings
      #
      # Returns a String with the PuppetDB URL
      def self.puppetdb_url(config = {})
        answer = [
          config.fetch("puppetdb", {}).fetch("url", nil),
          ENV["PUPPETDB_URL"]
        ].compact
        raise "PuppetDB URL not configured or set in environment" unless answer.any?
        answer.first
      end
    end
  end
end
