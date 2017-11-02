require 'docker'
require_relative '../docker_operations.rb'
require_relative '../build/info.rb'
require_relative '../build/check.rb'
require_relative '../build/image.rb'

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Build::Image.write_release_file
      location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
      DockerOperations.build(location, Build::Info.gitlab_registry_image_address, "latest")
    end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    # Only runs on dev.gitlab.org
    task :staging do
      registry = ENV['CI_REGISTRY']
      Build::Image.authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], registry)
      Build::Image.tag_and_push_to_gitlab_registry(Build::Info.docker_tag)
    end

    task :stable do
      Build::Image.authenticate
      Build::Image.tag_and_push_to_dockerhub(Build::Info.docker_tag)
    end

    # Special tags
    task :nightly do
      if Build::Check.add_nightly_tag?
        Build::Image.authenticate
        Build::Image.tag_and_push_to_dockerhub('nightly')
      end
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      if Build::Check.add_rc_tag?
        Build::Image.authenticate
        Build::Image.tag_and_push_to_dockerhub('rc')
      end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      if Build::Check.add_latest_tag?
        Build::Image.authenticate
        Build::Image.tag_and_push_to_dockerhub('latest')
      end
    end

    desc "Push triggered Docker Image to GitLab Registry"
    task :triggered do
      registry = "https://registry.gitlab.com/v2/"
      docker_tag = ENV['IMAGE_TAG']
      Build::Image.authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], registry)
      Build::Image.tag_and_push_to_gitlab_registry(docker_tag)
      puts "Pushed tag: #{docker_tag}"
    end
  end

  desc "Pull Docker Image from Registry"
  namespace :pull do
    task :staging do
      Build::Image.authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], ENV['CI_REGISTRY'])
      Docker::Image.create('fromImage' => "#{Build::Info.gitlab_registry_image_address}:#{Build::Info.docker_tag}")
      puts "Pulled tag: #{Build::Info.docker_tag}"
    end
  end
end
