require 'docker'
require_relative '../docker_operations.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Build.write_release_file
      location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
      DockerOperations.build(location, release_package, "latest")
    end

    desc "Build QA Docker image"
    task :qa do
      repo = release_package == "gitlab-ce" ? "gitlabhq" : "gitlab-ee"

      # PROCESS_ID is appended to ensure randomness in the directory name
      # to avoid possible conflicts that may arise if the clone's destination
      # directory already exists.
      system("git clone git@dev.gitlab.org:gitlab/#{repo}.git /tmp/#{repo}.#{$PROCESS_ID}")
      location = File.absolute_path("/tmp/#{repo}.#{$PROCESS_ID}/qa")
      DockerOperations.build(location, "gitlab-qa", "#{edition}-latest")
      FileUtils.rm_rf("/tmp/#{repo}.#{$PROCESS_ID}")
    end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    task :stable do
      authenticate
      push(tag)
      puts "Pushed tag: #{tag}"
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      if Build.add_rc_tag?
        authenticate
        push('rc')
        puts "Pushed tag: rc"
      end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      if Build.add_latest_tag?
        authenticate
        push('latest')
        puts "Pushed tag: latest"
      end
    end

    desc "Push QA Docker Image"
    task :qa do
      docker_tag = "#{edition}-#{tag}"
      authenticate
      DockerOperations.push("gitlab-qa", "#{edition}-latest", docker_tag)
      puts "Pushed tag: #{docker_tag}"
    end

    desc "Push triggered Docker Image to GitLab Registry"
    task :triggered do
      registry = "https://registry.gitlab.com/v2/"
      docker_tag = ENV["DOCKER_TAG"]
      authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], registry)
      push(docker_tag, ENV["CI_REGISTRY_IMAGE"])
      puts "Pushed tag: #{docker_tag}"
    end

    def tag
      Build.docker_tag
    end

    def push(docker_tag, repository = 'gitlab')
      DockerOperations.push(release_package, "latest", docker_tag, repository)
    end

    def authenticate(username = ENV['DOCKERHUB_USERNAME'], password = ENV['DOCKERHUB_PASSWORD'], serveraddress = "")
      DockerOperations.authenticate(user, token, registry)
    end
  end

  def release_package
    Build.package
  end

  def edition
    release_package.gsub("gitlab-", "").strip # 'ee' or 'ce'
  end
end
