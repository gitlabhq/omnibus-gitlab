require_relative 'gitlab_image'
require_relative 'image'
require_relative 'info/qa'

module Build
  class QAImage
    extend Image

    def self.dockerhub_image_name
      "#{Build::GitlabImage.dockerhub_image_name}-qa"
    end

    def self.gitlab_registry_image_name
      "#{Build::GitlabImage.gitlab_registry_image_name}-qa"
    end

    def self.source_image_address
      Build::Info::QA.image
    end
  end
end
