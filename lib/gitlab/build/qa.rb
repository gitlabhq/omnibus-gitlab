require_relative 'info.rb'

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
        system("git --git-dir=/tmp/gitlab.#{$PROCESS_ID}/.git --work-tree=/tmp/gitlab.#{$PROCESS_ID} checkout --quiet #{Info.gitlab_version}")
      end
    end
  end
end
