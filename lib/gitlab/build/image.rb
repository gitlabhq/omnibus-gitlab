require_relative "info.rb"
require_relative "../docker_operations.rb"
require 'net/http'
require 'json'

module Build
  class Image
    class << self
      def authenticate(user = ENV['DOCKERHUB_USERNAME'], token = ENV['DOCKERHUB_PASSWORD'], registry = "")
        DockerOperations.authenticate(user, token, registry)
      end

      def tag_and_push_to_dockerhub(final_tag)
        DockerOperations.tag_and_push(Info.gitlab_registry_image_address, Info.dockerhub_image_name, Info.docker_tag, final_tag)
        puts "Pushed tag: #{Info.dockerhub_image_name}:#{final_tag} to Docker Hub"
      end

      def tag_and_push_to_gitlab_registry(final_tag)
        DockerOperations.tag_and_push(Info.gitlab_registry_image_address, Info.gitlab_registry_image_address, 'latest', final_tag)
        puts "Pushed tag: #{Info.gitlab_registry_image_address}:#{final_tag}"
      end

      def pull
        Docker::Image.create('fromImage' => "#{Build::Info.gitlab_registry_image_address}:#{Build::Info.docker_tag}")
        puts "Pulled tag: #{Build::Info.docker_tag}"
      end

      def write_release_file
        contents = Info.release_file_contents
        File.write('docker/RELEASE', contents)
        contents
      end

      def fetch_artifact_url(project_id, pipeline_id)
        uri = URI("https://gitlab.com/api/v4/projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
        req = Net::HTTP::Get.new(uri)
        req['PRIVATE-TOKEN'] = ENV["TRIGGER_PRIVATE_TOKEN"]
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true
        res = http.request(req)
        output = JSON.parse(res.body)
        output.find { |job| job['name'] == 'Trigger:package' }['id']
      end
    end
  end
end
