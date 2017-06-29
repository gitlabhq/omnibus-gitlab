require 'docker'
require_relative '../docker_operations.rb'
require_relative '../build.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Build.write_release_file
      location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
      DockerOperations.build(location, image_name, "latest")
    end

    desc "Build QA Docker image"
    task :qa do
      # PROCESS_ID is appended to ensure randomness in the directory name
      # to avoid possible conflicts that may arise if the clone's destination
      # directory already exists.
      system("git clone #{gitlab_rails_repo} /tmp/gitlab.#{$PROCESS_ID}")

      # The below code is for handling triggered builds. In case of triggered
      # builds, we want to use the qa folder from the commit from which the
      # build was triggered, not master. This is needed when the change to test
      # is in the qa folder.
      checkout_version = if ENV['GITLAB_VERSION'].nil? || ENV['GITLAB_VERSION'].empty?
                           File.read('VERSION').strip
                         else
                           ENV['GITLAB_VERSION']
                         end

      # Checking out the cloned repo to the specific commit (well, without doing
      # a to-and-fro `cd`).
      system("git --git-dir=/tmp/gitlab.#{$PROCESS_ID}/.git --work-tree=/tmp/gitlab.#{$PROCESS_ID} checkout --quiet #{checkout_version}")

      location = File.absolute_path("/tmp/gitlab.#{$PROCESS_ID}/qa")
      DockerOperations.build(location, "gitlab/gitlab-qa", "#{edition}-latest")

      # For triggered builds, we need the QA image's tag to match the docker
      # tag. So, we are retagging the image.
      if ENV['IMAGE_TAG'] && !ENV['IMAGE_TAG'].empty?
        DockerOperations.tag("gitlab/gitlab-qa", "#{edition}-latest", "#{edition}-#{ENV['IMAGE_TAG']}")
      end
      FileUtils.rm_rf("/tmp/gitlab.#{$PROCESS_ID}")
    end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    # Only runs on dev.gitlab.org
    task :staging do
      registry = ENV['CI_REGISTRY']
      authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], registry)
      push(tag, ENV['CI_REGISTRY_IMAGE'])
    end

    task :stable do
      authenticate
      push_to_dockerhub(tag)
    end

    # Special tags
    task :nightly do
      if Build.add_nightly_tag?
        authenticate
        push_to_dockerhub('nightly')
      end
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      if Build.add_rc_tag?
        authenticate
        push_to_dockerhub('rc')
      end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      if Build.add_latest_tag?
        authenticate
        push_to_dockerhub('latest')
      end
    end

    desc "Push QA Docker Image"
    task :qa do
      docker_tag = "#{edition}-#{tag}"
      authenticate
      DockerOperations.push_image("gitlab/gitlab-qa", "#{edition}-latest", docker_tag)
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
  end

  desc "Pull Docker Image from Registry"
  namespace :pull do
    task :staging do
      registry = ENV['CI_REGISTRY']
      authenticate("gitlab-ci-token", ENV["CI_JOB_TOKEN"], registry)
      Docker::Image.create('fromImage' => "#{image_name}:#{tag}")
      puts "Pulled tag: #{tag}"
    end
  end

  def tag
    Build.docker_tag
  end

  def release_package
    Build.package
  end

  def edition
    release_package.gsub("gitlab-", "").strip # 'ee' or 'ce'
  end

  def image_name
    "#{ENV['CI_REGISTRY_IMAGE']}/#{release_package}"
  end

  def push(docker_tag, repository = 'gitlab')
    namespace = "#{repository}/#{release_package}"
    DockerOperations.push_image(namespace, "latest", docker_tag)
  end

  def authenticate(user = ENV['DOCKERHUB_USERNAME'], token = ENV['DOCKERHUB_PASSWORD'], registry = "")
    DockerOperations.authenticate(user, token, registry)
  end

  def push_to_dockerhub(final_tag)
    # Use the local image
    image = DockerOperations.get(image_name, tag)
    # Create different tags and push to dockerhub
    DockerOperations.tag_and_push(image, "gitlab/#{release_package}", final_tag)
    puts "Pushed tag: #{final_tag}"
  end

  def gitlab_rails_repo
    # For normal builds, QA build happens from the gitlab repositories in dev.
    # For triggered builds, they are not available and their gitlab.com mirrors
    # have to be used.

    if ENV['ALTERNATIVE_SOURCES'].to_s == "true"
      domain = "https://gitlab.com/gitlab-org"
      project = release_package
    else
      domain = "git@dev.gitlab.org:gitlab"
      project = release_package == "gitlab-ce" ? "gitlabhq" : "gitlab-ee"
    end

    "#{domain}/#{project}.git"
  end
end
