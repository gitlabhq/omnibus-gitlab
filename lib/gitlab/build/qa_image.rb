require_relative 'image'
require_relative 'gitlab_image'
require_relative '../skopeo_helper'

module Build
  class QAImage
    extend Image

    def self.dockerhub_image_name
      "#{Build::GitlabImage.dockerhub_image_name}-qa"
    end

    def self.gitlab_registry_image_name
      "#{Build::GitlabImage.gitlab_registry_image_name}-qa"
    end

    def self.copy_image_to_omnibus_registry(final_tag)
      source = Build::Info.qa_image
      target = Build::QAImage.gitlab_registry_image_address(tag: final_tag)

      SkopeoHelper.login('gitlab-ci-token', Gitlab::Util.get_env('CI_JOB_TOKEN'), Gitlab::Util.get_env('CI_REGISTRY'))

      SkopeoHelper.copy_image(source, target)
    end

    def self.copy_image_to_dockerhub(final_tag)
      source = Build::Info.qa_image
      target = "#{dockerhub_image_name}:#{final_tag}"

      SkopeoHelper.login('gitlab-ci-token', Gitlab::Util.get_env('CI_JOB_TOKEN'), Gitlab::Util.get_env('CI_REGISTRY'))
      SkopeoHelper.login(Gitlab::Util.get_env('DOCKERHUB_USERNAME'), Gitlab::Util.get_env('DOCKERHUB_PASSWORD'), 'docker.io')

      SkopeoHelper.copy_image(source, target)
    end
  end
end
