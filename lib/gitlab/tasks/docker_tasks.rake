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

  desc "Push Docker Image to Registry"
  namespace :push do
    task :stable do
      docker_tag = Build.docker_tag
      puts "Pushing tag: #{docker_tag}"
      auth_and_push(docker_tag)
    end

    task :rc do
      # push as :rc tag, the :rc is always the latest tagged release

      if Build.add_rc_tag?
        auth_and_push('rc')
        puts "Pushing tag: rc"
      end
    end

    task :latest do
      # push as :latest tag, the :latest is always the latest stable release

      if Build.add_latest_tag?
        auth_and_push('latest')
        puts "Pushing tag: latest"
      end
    end

    def auth_and_push(tag)
      release_package = Build.package
      DockerOperations.authenticate
      DockerOperations.push(release_package, "latest", tag)
    end
  end

  desc "Push QA Docker Image to Registry"
  task :push_qa do
    docker_tag = Build.docker_tag
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
