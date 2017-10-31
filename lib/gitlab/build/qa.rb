require_relative 'info.rb'
require_relative 'check.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

module Build
  class QA
    class << self
      def get_gitlab_repo
        QA.clone_gitlab_rails
        QA.checkout_gitlab_rails
        File.absolute_path("/tmp/gitlab.#{$PROCESS_ID}/qa")
      end

      def clone_gitlab_rails
        # PROCESS_ID is appended to ensure randomness in the directory name
        # to avoid possible conflicts that may arise if the clone's destination
        # directory already exists.
        system("git clone #{Info.gitlab_rails_repo} /tmp/gitlab.#{$PROCESS_ID}")
      end

      def checkout_gitlab_rails
        # Checking out the cloned repo to the specific commit (well, without doing
        # a to-and-fro `cd`).
        version = Info.gitlab_version

        # Tags have a 'v' prepended to them, which is not present in VERSION file.
        version = "v#{version}" if Check.on_tag?

        system("git --git-dir=/tmp/gitlab.#{$PROCESS_ID}/.git --work-tree=/tmp/gitlab.#{$PROCESS_ID} checkout --quiet #{version}")
      end

      def image_name
        "gitlab/#{Info.package}-qa"
      end
    end
  end
end
