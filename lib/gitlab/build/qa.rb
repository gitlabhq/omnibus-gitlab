require_relative 'info'
require_relative 'check'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

module Build
  class QA
    def self.repo_path
      File.absolute_path("/tmp/gitlab")
    end

    def self.get_gitlab_repo
      clone_gitlab_rails
      checkout_gitlab_rails
      cleanup_directories

      repo_path
    end

    def self.clone_gitlab_rails
      system(*%W[rm -rf #{repo_path}])
      system(*%W[git clone #{Build::Info.gitlab_rails_repo} #{repo_path}])
    end

    def self.get_gitlab_rails_sha
      # Finding out which commit was the package built from
      begin
        version_manifest = JSON.parse(File.read("pkg/ubuntu-xenial/#{Build::Info.package}_#{Build::Info.release_version}.version-manifest.json"))
        version = version_manifest['software']['gitlab-rails']['locked_version']
      rescue Errno::ENOENT, JSON::ParserError
        puts "Failed to get commit from version-manifest file"
        # Fall back to using gitlab_version
        version = Build::Info.gitlab_version

        # Tags have a 'v' prepended to them, which is not present in VERSION file.
        # Unless the tag is an auto-deploy tag
        version = "v#{version}" if Build::Check.on_tag? && !Build::Check.is_auto_deploy?
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

    def self.cleanup_directories
      system(*%W[rm -rf #{repo_path}/changelogs/unreleased #{repo_path}/ee/changelogs/unreleased])
    end
  end
end
