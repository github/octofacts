# This class contains methods to interact with the GitHub API.
# frozen_string_literal: true

require "octokit"
require "pathname"

module OctofactsUpdater
  module Service
    class GitHub
      attr_reader :options

      # Callable external method: Push all changes to the indicated paths to GitHub.
      #
      # root    - A String with the root directory, to which paths are relative.
      # paths   - An Array of Strings, which are relative to the repository root.
      # options - A Hash with configuration options.
      #
      # Returns true if there were any changes made, false otherwise.
      def self.run(root, paths, options = {})
        root ||= options.fetch("github", {})["base_directory"]
        unless root && File.directory?(root)
          raise ArgumentError, "Base directory must be specified"
        end
        github = new(options)
        project_root = Pathname.new(root)
        paths.each do |path|
          absolute_path = Pathname.new(path)
          stripped_path = absolute_path.relative_path_from(project_root)
          github.commit_data(stripped_path.to_s, File.read(path))
        end
        github.finalize_commit
      end

      # Constructor.
      #
      # options - Hash with options
      def initialize(options = {})
        @options = options
        @verbose = github_options.fetch("verbose", false)
        @changes = []
      end

      # Commit a file to a location in the repository with the provided message. This will return true if there was
      # an actual change, and false otherwise. This method does not actually do the commit, but rather it batches up
      # all of the changes which must be realized later.
      #
      # path        - A String with the path at which to commit the file
      # new_content - A String with the new contents
      #
      # Returns true (and updates @changes) if there was actually a change, false otherwise.
      def commit_data(path, new_content)
        ensure_branch_exists

        old_content = nil
        begin
          contents = octokit.contents(repository, path: path, ref: branch)
          old_content = Base64.decode64(contents.content)
        rescue Octokit::NotFound
          verbose("No old content found in #{repository.inspect} at #{path.inspect} in #{branch.inspect}")
          # Fine, we will add below.
        end

        if new_content == old_content
          verbose("Content of #{path} matches, no commit needed")
          return false
        else
          verbose("Content of #{path} does not match. A commit is needed.")
          verbose(Diffy::Diff.new(old_content, new_content))
        end

        @changes << Hash(
          path: path,
          mode: "100644",
          type: "blob",
          sha: octokit.create_blob(repository, new_content)
        )

        verbose("Batched update of #{path}")
        true
      end

      # Finalize the GitHub commit by actually pushing any of the changes. This will not do anything if there
      # are not any changes batched via the `commit_data` method.
      #
      # message - A String with a commit message, defaults to the overall configured commit message.
      def finalize_commit(message = commit_message)
        return unless @changes.any?

        ensure_branch_exists
        branch_ref = octokit.branch(repository, branch)
        commit = octokit.git_commit(repository, branch_ref[:commit][:sha])
        tree = commit["tree"]
        new_tree = octokit.create_tree(repository, @changes, base_tree: tree["sha"])
        new_commit = octokit.create_commit(repository, message, new_tree["sha"], commit["sha"])
        octokit.update_ref(repository, "heads/#{branch}", new_commit["sha"])
        verbose("Committed #{@changes.size} change(s) to GitHub")
        find_or_create_pull_request
      end

      # Delete a file from the repository. Because of the way the GitHub API works, this will generate an
      # immediate commit and push. It will NOT be batched for later application.
      #
      # path    - A String with the path at which to commit the file
      # message - A String with a commit message, defaults to the overall configured commit message.
      #
      # Returns true if the file existed before and was deleted. Returns false if the file didn't exist anyway.
      def delete_file(path, message = commit_message)
        ensure_branch_exists
        contents = octokit.contents(repository, path: path, ref: branch)
        blob_sha = contents.sha
        octokit.delete_contents(repository, path, message, blob_sha, branch: branch)
        verbose("Deleted #{path}")
        find_or_create_pull_request
        true
      rescue Octokit::NotFound
        verbose("Deleted #{path} (already gone)")
        false
      end

      private

      # Private: Build an octokit object from the provided options.
      #
      # Returns an octokit object.
      def octokit
        @octokit ||= begin
          token = options.fetch("github", {})["token"] || ENV["OCTOKIT_TOKEN"]
          if token
            Octokit::Client.new(access_token: token)
          else
            raise ArgumentError, "Access token must be provided in config file or OCTOKIT_TOKEN environment variable."
          end
        end
      end

      # Private: Get the default branch from the repository. Unless default_branch is specified in the options, then use
      # that instead.
      #
      # Returns a String with the name of the default branch.
      def default_branch
        github_options["default_branch"] || octokit.repo(repository)[:default_branch]
      end

      # Private: Ensure branch exists. This will use octokit to create the branch on GitHub if the branch
      # does not already exist.
      def ensure_branch_exists
        @ensure_branch_exists ||= begin
          created = false
          begin
            if octokit.branch(repository, branch)
              verbose("Branch #{branch} already exists in #{repository}.")
              created = true
            end
          rescue Octokit::NotFound
            # Fine, we'll create it
          end

          unless created
            base_sha = octokit.branch(repository, default_branch)[:commit][:sha]
            octokit.create_ref(repository, "heads/#{branch}", base_sha)
            verbose("Created branch #{branch} based on #{default_branch} #{base_sha}.")
          end

          true
        end
      end

      # Private: Find an existing pull request for the branch, and commit a new pull request if
      # there was not an existing one open.
      #
      # Returns the pull request object that was created.
      def find_or_create_pull_request
        @find_or_create_pull_request ||= begin
          prs = octokit.pull_requests(repository, head: "github:#{branch}", state: "open")
          if prs && !prs.empty?
            verbose("Found existing PR #{prs.first.html_url}")
            prs.first
          else
            new_pr = octokit.create_pull_request(
              repository,
              default_branch,
              branch,
              pr_subject,
              pr_body
            )
            verbose("Created a new PR #{new_pr.html_url}")
            new_pr
          end
        end
      end

      # Simple methods not covered by unit tests explicitly.
      # :nocov:

      # Log a verbose message.
      #
      # message - A String with the message to print.
      def verbose(message)
        return unless @verbose
        puts "*** #{Time.now}: #{message}"
      end

      def github_options
        return {} unless options.is_a?(Hash)
        options.fetch("github", {})
      end

      def repository
        github_options.fetch("repository")
      end

      def branch
        github_options.fetch("branch")
      end

      def commit_message
        github_options.fetch("commit_message")
      end

      def pr_subject
        github_options.fetch("pr_subject")
      end

      def pr_body
        github_options.fetch("pr_body")
      end
      # :nocov:
    end
  end
end
