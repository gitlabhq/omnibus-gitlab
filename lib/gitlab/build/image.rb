require_relative 'info'
require_relative '../docker_operations'

module Build
  module Image
    def pull
      Docker::Image.create(
        'fromImage' => "#{gitlab_registry_image_address}:#{Build::Info.docker_tag}"
      )
      puts "Pulled tag: #{Build::Info.docker_tag}"
    end

    def gitlab_registry_image_address(tag: nil)
      address = "#{ENV['CI_REGISTRY_IMAGE']}/#{gitlab_registry_image_name}"
      address << ":#{tag}" if tag

      address
    end

    def tag_and_push_to_gitlab_registry(final_tag)
      DockerOperations.authenticate('gitlab-ci-token', ENV['CI_JOB_TOKEN'], ENV['CI_REGISTRY'])
      DockerOperations.tag_and_push(
        gitlab_registry_image_address,
        gitlab_registry_image_address,
        'latest',
        final_tag
      )
      puts "Pushed #{gitlab_registry_image_address}:#{final_tag}"
    end

    def tag_and_push_to_dockerhub(final_tag)
      DockerOperations.authenticate(ENV['DOCKERHUB_USERNAME'], ENV['DOCKERHUB_PASSWORD'])
      DockerOperations.tag_and_push(
        gitlab_registry_image_address,
        dockerhub_image_name,
        Build::Info.docker_tag,
        final_tag
      )
      puts "Pushed #{dockerhub_image_name}:#{final_tag} to Docker Hub"
    end

    def write_release_file
      contents = Build::Info.release_file_contents
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
