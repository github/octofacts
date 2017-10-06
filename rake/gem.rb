## Releasing a new version of octofacts
##
## 1. Update `.version` with new version number
## 2. Run `script/bootstrap` to update Gemfile.lock
## 3. Commit changes, PR, and merge to master
## 4. Check out master branch locally
## 5. Run `bundle exec rake gem:release`

require "fileutils"
require "open3"
require "shellwords"

module Octofacts
  # A class to contain methods and constants for cleaner code
  class Gem
    BASEDIR = File.expand_path("..", File.dirname(__FILE__)).freeze
    GEMS = ["octofacts", "octofacts-updater"].freeze
    PKGDIR = File.join(BASEDIR, "pkg").freeze

    # Verify that Gemfile.lock matches .version and that it's committed, since `bundle exec ...` will
    # update the file for us.
    def self.verify_gemfile_version!
      bundler = Bundler::LockfileParser.new(Bundler.read_file(File.expand_path("../Gemfile.lock", File.dirname(__FILE__))))
      gems = bundler.specs.select { |specs| GEMS.include?(specs.name) }
      GEMS.each do |gem|
        this_gem = gems.detect { |g| g.name == gem }
        unless this_gem
          raise "Did not find #{gem} in Gemfile.lock"
        end
        unless this_gem.version.to_s == version
          raise "Gem #{gem} is version #{this_gem.version}, not #{version}"
        end
      end

      puts "Ensuring that all changes are committed."
      exec_command("git diff-index --quiet HEAD --")
      puts "OK: All gems on #{version} and no uncommitted changes here."
    end

    # Read the version number from the .version file in the root of the project.
    def self.version
      @version ||= File.read(File.expand_path("../.version", File.dirname(__FILE__))).strip
    end

    # Determine what branch we are on
    def self.branch
      exec_command("git rev-parse --abbrev-ref HEAD").strip
    end

    # Build the gem and put it into the 'pkg' directory
    def self.build
      Dir.mkdir PKGDIR unless File.directory?(PKGDIR)
      GEMS.each do |gem|
        begin
          output_file = File.join(BASEDIR, "#{gem}-#{version}.gem")
          target_file = File.join(PKGDIR, "#{gem}-#{version}.gem")
          exec_command("gem build #{gem}.gemspec")
          unless File.file?(output_file)
            raise "gem #{gem} failed to create expected output file"
          end
          FileUtils.mv output_file, target_file
          puts "Generated #{target_file}"
        ensure
          # Clean up the *.gem generated in the main directory if it's still there
          FileUtils.rm(output_file) if File.file?(output_file)
        end
      end
    end

    # Push the gem to rubygems
    def self.push
      GEMS.each do |gem|
        target_file = File.join(PKGDIR, "#{gem}-#{version}.gem")
        unless File.file?(target_file)
          raise "Cannot push: #{target_file} does not exist"
        end
      end
      GEMS.each do |gem|
        target_file = File.join(PKGDIR, "#{gem}-#{version}.gem")
        exec_command("gem push #{Shellwords.escape(target_file)}")
      end
    end

    # Tag the release on GitHub
    def self.tag
      # Make sure we have not released this version before
      exec_command("git fetch -t origin")
      tags = exec_command("git tag -l").split(/\n/)
      raise "There is already a #{version} tag" if tags.include?(version)

      # Tag it
      exec_command("git tag #{Shellwords.escape(version)}")
      exec_command("git push origin master")
      exec_command("git push origin #{Shellwords.escape(version)}")
    end

    # Yank gem from rubygems
    def self.yank
      GEMS.each do |gem|
        exec_command("gem yank #{gem} -v #{Shellwords.escape(version)}")
      end
    end

    # Utility method: Execute command
    def self.exec_command(command)
      STDERR.puts "Command: #{command}"
      output, code = Open3.capture2e(command, chdir: BASEDIR)
      return output if code.exitstatus.zero?
      STDERR.puts "Output:\n#{output}"
      STDERR.puts "Exit code: #{code.exitstatus}"
      exit code.exitstatus
    end
  end
end

namespace :gem do
  task "build" do
    branch = Octofacts::Gem.branch
    unless branch == "master"
      raise "On a non-master branch #{branch}; use gem:force-build if you really want to do this"
    end
    Octofacts::Gem.build
  end

  task "check" do
    Octofacts::Gem.verify_gemfile_version!
  end

  task "force-build" do
    branch = Octofacts::Gem.branch
    unless branch == "master"
      warn "WARNING: Force-building from non-master branch #{branch}"
    end
    Octofacts::Gem.build
  end

  task "push" do
    Octofacts::Gem.push
  end

  task "release" do
    branch = Octofacts::Gem.branch
    unless branch == "master"
      raise "On a non-master branch #{branch}; refusing to release"
    end
    [:check, :build, :tag, :push].each { |t| Rake::Task["gem:#{t}"].invoke }
  end

  task "tag" do
    branch = Octofacts::Gem.branch
    raise "On a non-master branch #{branch}; refusing to tag" unless branch == "master"
    Octofacts::Gem.tag
  end

  task "yank" do
    Octofacts::Gem.yank
  end
end
