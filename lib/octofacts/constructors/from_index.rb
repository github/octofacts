# frozen_string_literal: true
module Octofacts
  # Octofacts.from_index(options) - Construct Octofacts::Facts from an index file.
  #
  # Returns an Octofacts::Facts object.
  def self.from_index(opts = {})
    Octofacts::Facts.new(backend: Octofacts::Backends::Index.new(opts), options: opts)
  end
end
