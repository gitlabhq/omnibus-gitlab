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

      def dockerhub_image_name
        'gitlab/gitlab-qa'
      end

      def gitlab_registry_image_name
        'gitlab-qa'
      end

      def latest_tag
        "#{Info.edition}-latest"
      end

      def gitlab_registry_image_address(tag: nil)
        address = "#{ENV['CI_REGISTRY_IMAGE']}/#{QA.gitlab_registry_image_name}"
        address << ":#{tag}" if tag

        address
      end

      def tag_triggered_qa
        return unless ENV['IMAGE_TAG'] && !ENV['IMAGE_TAG'].empty?

        # For triggered builds, we need the QA image's tag to match the docker
        # tag. So, we are retagging the image.
        DockerOperations.tag(QA.gitlab_registry_image_address, QA.dockerhub_image_name, latest_tag, "#{Info.edition}-#{ENV['IMAGE_TAG']}")
      end

      def tag_and_push_to_dockerhub(final_tag)
        DockerOperations.tag_and_push(QA.gitlab_registry_image_address, QA.dockerhub_image_name, latest_tag, final_tag)
        puts "Pushed tag: #{final_tag} to Docker Hub"
      end

      def tag_and_push_to_gitlab_registry(final_tag)
        DockerOperations.tag_and_push(QA.gitlab_registry_image_address, QA.gitlab_registry_image_address, latest_tag, final_tag)
        puts "Pushed tag: #{final_tag} to #{QA.gitlab_registry_image_address}"
      end
    end
  end
end
