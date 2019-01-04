require_relative 'info'
require_relative 'check'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

module Build
  class QA
    def self.repo_path
      "/tmp/gitlab.#{$PROCESS_ID}"
    end

    def self.get_gitlab_repo
      clone_gitlab_rails
      checkout_gitlab_rails
      File.absolute_path("#{repo_path}/qa")
    end

    def self.clone_gitlab_rails
      # PROCESS_ID is appended to ensure randomness in the directory name
      # to avoid possible conflicts that may arise if the clone's destination
      # directory already exists.
      system(*%W[git clone #{Build::Info.gitlab_rails_repo} #{repo_path}])
    end

    def self.get_gitlab_rails_sha
      # Finding out which commit was the package built from
      begin
        version_manifest = JSON.parse(File.read("pkg/ubuntu-xenial/version-manifest.json"))
        version = version_manifest['software']['gitlab-rails']['locked_version']
      rescue Errno::ENOENT, JSON::ParserError
        puts "Failed to get commit from version-manifest file"
        # Fall back to using gitlab_version
        version = Build::Info.gitlab_version

        # Tags have a 'v' prepended to them, which is not present in VERSION file.
        version = "v#{version}" if Build::Check.on_tag?
      end

      version
    end

    def self.checkout_gitlab_rails
      # Checking out the cloned repo to the specific commit (well, without doing
      # a to-and-fro `cd`).
      version = get_gitlab_rails_sha
      puts "Building from #{Build::Info.package} commit #{version}"

      system(*%W[git --git-dir=#{repo_path}/.git --work-tree=#{repo_path} checkout --quiet #{version}])
    end
  end
end
