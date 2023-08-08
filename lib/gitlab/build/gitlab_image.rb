require_relative 'image'
require_relative 'info'

module Build
  class GitlabImage
    extend Image

    def self.dockerhub_image_name
      "gitlab/#{Build::Info::Package.name}"
    end

    def self.gitlab_registry_image_name
      Build::Info::Package.name
    end
  end
end
