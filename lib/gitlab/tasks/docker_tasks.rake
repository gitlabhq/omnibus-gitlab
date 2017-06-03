require 'docker'
require_relative '../docker_operations.rb'
require_relative '../build.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

namespace :docker do
  desc "Build Docker image"
  task :build do
    release_package = Build.package
    Build.write_release_file
    location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
    DockerOperations.build(location, release_package, "latest")
  end

  desc "Build QA Docker image"
  task :build_qa do
    release_package = Build.package
    repo = release_package == "gitlab-ce" ? "gitlabhq" : "gitlab-ee"
    type = release_package.gsub("gitlab-", "").strip

    # PROCESS_ID is appended to ensure randomness in the directory name
    # to avoid possible conflicts that may arise if the clone's destination
    # directory already exists.
    system("git clone git@dev.gitlab.org:gitlab/#{repo}.git /tmp/#{repo}.#{$PROCESS_ID}")
    location = File.absolute_path("/tmp/#{repo}.#{$PROCESS_ID}/qa")
    DockerOperations.build(location, "gitlab-qa", "#{type}-latest")
    FileUtils.rm_rf("/tmp/#{repo}.#{$PROCESS_ID}")
  end

  desc "Clean Docker stuff"
  task :clean do
    release_package = Build.package
    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images(release_package)
  end

  desc "Clean QA Docker stuff"
  task :clean_qa do
    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images("gitlab-qa")
  end

  desc "Push Docker Image to Registry"
  task :push do
    docker_tag = ENV["DOCKER_TAG"]
    release_package = Build.package
    DockerOperations.authenticate
    DockerOperations.push(release_package, "latest", docker_tag)
  end

  desc "Push QA Docker Image to Registry"
  task :push_qa do
    docker_tag = ENV["DOCKER_TAG"]
    release_package = Build.package
    type = release_package.gsub("gitlab-", "").strip
    DockerOperations.authenticate
    DockerOperations.push("gitlab-qa", "#{type}-latest", "#{type}-#{docker_tag}")
  end

  desc "Push triggered Docker Image to GitLab Registry"
  task :push_triggered do
    release_package = Build.package
    docker_tag = ENV["DOCKER_TAG"]
    docker_registry = "https://registry.gitlab.com/v2/"
    DockerOperations.authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], docker_registry)
    DockerOperations.push(release_package, "latest", docker_tag, ENV["CI_REGISTRY_IMAGE"])
  end
end
