# frozen_string_literal: true
require "octofacts_updater/cli"
require "octofacts_updater/fact"
require "octofacts_updater/fact_index"
require "octofacts_updater/fixture"
require "octofacts_updater/plugin"
require "octofacts_updater/plugins/ip"
require "octofacts_updater/plugins/ssh"
require "octofacts_updater/plugins/static"
require "octofacts_updater/service/base"
require "octofacts_updater/service/enc"
require "octofacts_updater/service/github"
require "octofacts_updater/service/local_file"
require "octofacts_updater/service/puppetdb"
require "octofacts_updater/service/ssh"
require "octofacts_updater/version"

module OctofactsUpdater
  #
end
