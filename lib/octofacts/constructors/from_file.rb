# frozen_string_literal: true
module Octofacts
  # Octofacts.from_file(filename, options) - Construct Octofacts::Facts from a filename.
  #
  # filename - Relative or absolute path to the file containing the facts.
  # opts[:octofacts_fixture_path] - Directory where fact fixture files are found (default: ENV["OCTOFACTS_FIXTURE_PATH"])
  #
  # Returns an Octofacts::Facts object.
  def self.from_file(filename, opts = {})
    unless filename.start_with? "/"
      dir = Octofacts::Util::Config.fetch(:octofacts_fixture_path, opts)
      raise ArgumentError, ".from_file needs to know :octofacts_fixture_path or environment OCTOFACTS_FIXTURE_PATH" unless dir
      raise Errno::ENOENT, "The provided fixture path #{dir} is invalid" unless File.directory?(dir)
      filename = File.join(dir, filename)
    end

    Octofacts::Facts.new(backend: Octofacts::Backends::YamlFile.new(filename), options: opts)
  end
end
