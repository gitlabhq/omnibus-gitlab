require_relative 'image'
require_relative 'info'

module Build
  class GitlabImage
    extend Image

    def self.dockerhub_image_name
      "gitlab/#{Build::Info.package}"
    end

    def self.gitlab_registry_image_name
      Build::Info.package
    end
  end
end
