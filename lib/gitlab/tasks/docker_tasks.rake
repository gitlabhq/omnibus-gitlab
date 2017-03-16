require 'docker'
require_relative '../docker_operations.rb'

namespace :docker do
  desc "Build Docker image"
  task :build, [:RELEASE_PACKAGE] do |_t, args|
    release_package = args['RELEASE_PACKAGE']
    location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
    Docker.options[:read_timeout] = 600
    Docker::Image.build_from_dir(location.to_s, { t: "#{release_package}:latest", pull: true }) do |chunk|
      if (log = JSON.parse(chunk)) && log.key?("stream")
        puts log["stream"]
      end
    end
  end

  desc "Clean Docker stuff"
  task :clean, [:RELEASE_PACKAGE] do |_t, args|
    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images(args['RELEASE_PACKAGE'])
  end

  desc "Push Docker Image to Registry"
  task :push, [:RELEASE_PACKAGE] do |_t, args|
    docker_tag = ENV["DOCKER_TAG"]
    release_package = args['RELEASE_PACKAGE']
    image = Docker::Image.get("#{release_package}:latest")

    image.info["RepoTags"].pop
    image.tag(repo: "gitlab/#{release_package}", tag: docker_tag.to_s, force: true)
    puts image.info["RepoTags"]
    Docker.authenticate!(username: ENV['DOCKERHUB_USERNAME'], password: ENV['DOCKERHUB_PASSWORD'], email: ENV['DOCKERHUB_EMAIL'])
    image.push(Docker.creds, repo_tag: "gitlab/#{release_package}:#{docker_tag}") do |chunk|
      puts chunk
    end
  end
end
