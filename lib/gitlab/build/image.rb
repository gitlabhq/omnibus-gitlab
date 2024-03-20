require_relative '../util'
require_relative '../skopeo_helper'
require_relative '../docker_operations'
require_relative 'info/docker'

module Build
  module Image
    def pull
      Docker::Image.create(
        'fromImage' => "#{gitlab_registry_image_address}:#{Build::Info::Docker.tag}"
      )
      puts "Pulled tag: #{Build::Info::Docker.tag}"
    end

    def gitlab_registry_image_address(tag: nil)
      address = "#{Gitlab::Util.get_env('CI_REGISTRY_IMAGE')}/#{gitlab_registry_image_name}"
      address << ":#{tag}" if tag

      address
    end

    def tag_and_push_to_gitlab_registry(final_tag)
      DockerOperations.authenticate('gitlab-ci-token', Gitlab::Util.get_env('CI_JOB_TOKEN'), Gitlab::Util.get_env('CI_REGISTRY'))
      DockerOperations.tag_and_push(
        gitlab_registry_image_address,
        gitlab_registry_image_address,
        'latest',
        final_tag
      )
      puts "Pushed #{gitlab_registry_image_address}:#{final_tag}"
    end

    def tag_and_push_to_dockerhub(final_tag, initial_tag: Build::Info::Docker.tag)
      DockerOperations.authenticate(Gitlab::Util.get_env('DOCKERHUB_USERNAME'), Gitlab::Util.get_env('DOCKERHUB_PASSWORD'))
      DockerOperations.tag_and_push(
        gitlab_registry_image_address,
        dockerhub_image_name,
        initial_tag,
        final_tag
      )
      puts "Pushed #{dockerhub_image_name}:#{final_tag} to Docker Hub"
    end

    def copy_image_to_dockerhub(final_tag)
      source = source_image_address
      target = "#{dockerhub_image_name}:#{final_tag}"

      SkopeoHelper.login('gitlab-ci-token', Gitlab::Util.get_env('CI_JOB_TOKEN'), Gitlab::Util.get_env('CI_REGISTRY'))
      SkopeoHelper.login(Gitlab::Util.get_env('DOCKERHUB_USERNAME'), Gitlab::Util.get_env('DOCKERHUB_PASSWORD'), 'docker.io')

      SkopeoHelper.copy_image(source, target)
    end

    def copy_image_to_gitlab_registry(final_tag)
      source = source_image_address
      target = gitlab_registry_image_address(tag: final_tag)

      SkopeoHelper.login('gitlab-ci-token', Gitlab::Util.get_env('CI_JOB_TOKEN'), Gitlab::Util.get_env('CI_REGISTRY'))

      SkopeoHelper.copy_image(source, target)
    end

    def source_image_address
      raise NotImplementedError
    end

    def write_release_file
      contents = Build::Info::Docker.release_file_contents
      File.write('docker/RELEASE', contents)
      contents
    end

    def gitlab_registry_image_name
      raise NotImplementedError
    end

    def dockerhub_image_name
      raise NotImplementedError
    end
  end
end
