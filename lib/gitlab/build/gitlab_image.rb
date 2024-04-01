require_relative 'image'
require_relative 'info/package'

module Build
  class GitlabImage
    extend Image

    def self.dockerhub_image_name
      "gitlab/#{Build::Info::Package.name}"
    end

    def self.gitlab_registry_image_name
      Build::Info::Package.name
    end

    def self.source_image_address
      gitlab_registry_image_address(tag: Build::Info::Docker.tag)
    end
  end
end
