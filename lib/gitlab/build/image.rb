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

      def push_to_dockerhub(final_tag, type = "gitlab")
        # Create different tags and push to dockerhub
        if type == "qa"
          DockerOperations.tag_and_push("gitlab/gitlab-qa", "gitlab/gitlab-qa", "#{Info.edition}-latest", final_tag)
        else
          DockerOperations.tag_and_push(Info.image_name, "gitlab/#{Info.package}", Info.docker_tag, final_tag)
        end
        puts "Pushed tag: #{final_tag}"
      end

      def tag_triggered_qa
        # For triggered builds, we need the QA image's tag to match the docker
        # tag. So, we are retagging the image.
        DockerOperations.tag("gitlab/gitlab-qa", "gitlab/gitlab-qa", "#{Info.edition}-latest", "#{Info.edition}-#{ENV['IMAGE_TAG']}") if ENV['IMAGE_TAG'] && !ENV['IMAGE_TAG'].empty?
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
