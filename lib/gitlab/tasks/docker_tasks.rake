require 'docker'
require_relative '../docker_operations.rb'

namespace :docker do

  desc "Build Docker image"
  task :build, [:RELEASE_PACKAGE] do |_t, args|
    RELEASE_PACKAGE = args['RELEASE_PACKAGE']
    location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
    Docker::Image.build_from_dir("#{location}", {:t => "#{RELEASE_PACKAGE}:latest", :pull => true })
  end

  desc "Clean Docker stuff"
  task :clean, [:RELEASE_PACKAGE] do |_t, args|

    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images(args['RELEASE_PACKAGE'])
  end

  desc "Push Docker Image to Registry"
  task :push, [:RELEASE_PACKAGE] do |_t, args|
    DOCKER_TAG = ENV["DOCKER_TAG"]
    RELEASE_PACKAGE = args['RELEASE_PACKAGE']
    image = Docker::Image.create(:fromImage => "#{RELEASE_PACKAGE}:latest")
    image.tag(:repo => "gitlab/#{RELEASE_PACKAGE}", :tag => "#{DOCKER_TAG}", :force => true)
    image.push(:tag => "#{DOCKER_TAG}")
  end
end
