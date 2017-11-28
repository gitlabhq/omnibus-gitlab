require_relative 'info.rb'
require_relative 'check.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

module Build
  class QAImage
    extend Image

    def self.dockerhub_image_name
      "#{Build::Image.dockerhub_image_name}-qa"
    end

    def self.gitlab_registry_image_name
      "#{Build::Image.gitlab_registry_image_name}-qa"
    end
  end
end
