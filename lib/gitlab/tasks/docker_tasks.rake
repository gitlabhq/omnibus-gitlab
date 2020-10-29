require 'docker'
require_relative '../docker_operations'
require_relative '../build/info'
require_relative '../build/check'
require_relative '../build/gitlab_image'
require_relative "../util.rb"
require_relative "../docker_image_memory_measurer.rb"

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Gitlab::Util.section_start('docker:build:image')

      Build::GitlabImage.write_release_file
      location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
      DockerOperations.build(
        location,
        Build::GitlabImage.gitlab_registry_image_address,
        'latest'
      )

      Gitlab::Util.section_end
    end
  end

  task :measure_memory do
    Gitlab::Util.section_start('docker:measure_memory')

    image_reference = Gitlab::Util.get_env('IMAGE_REFERENCE') || Build::Info.image_reference
    debug_output_dir = Gitlab::Util.get_env('DEBUG_OUTPUT_DIR')

    docker_image_memory_measurer = Gitlab::DockerImageMemoryMeasurer.new(image_reference, debug_output_dir)
    puts docker_image_memory_measurer.measure

    Gitlab::Util.section_end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    # Only runs on dev.gitlab.org
    task :staging do
      Gitlab::Util.section_start('docker:push:staging')
      Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info.docker_tag)
      Gitlab::Util.section_end
    end

    task :stable do
      Gitlab::Util.section_start('docker:push:stable')
      Build::GitlabImage.tag_and_push_to_dockerhub(Build::Info.docker_tag)
      Gitlab::Util.section_end
    end

    # Special tags
    task :nightly do
      Gitlab::Util.section_start('docker:push:nightly')
      Build::GitlabImage.tag_and_push_to_dockerhub('nightly') if Build::Check.is_nightly?
      Gitlab::Util.section_end
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      Gitlab::Util.section_start('docker:push:rc')
      Build::GitlabImage.tag_and_push_to_dockerhub('rc') if Build::Check.is_latest_tag?
      Gitlab::Util.section_end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      Gitlab::Util.section_start('docker:push:latest')
      Build::GitlabImage.tag_and_push_to_dockerhub('latest') if Build::Check.is_latest_stable_tag?
      Gitlab::Util.section_end
    end

    desc "Push triggered Docker Image to GitLab Registry"
    task :triggered do
      Gitlab::Util.section_start('docker:push:triggered')
      Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info.docker_tag)
      Gitlab::Util.section_end
    end
  end

  desc "Pull Docker Image from Registry"
  namespace :pull do
    task :staging do
      Gitlab::Util.section_start('docker:pull:staging')

      DockerOperations.authenticate("gitlab-ci-token", Gitlab::Util.get_env("CI_JOB_TOKEN"), Gitlab::Util.get_env('CI_REGISTRY'))
      Build::GitlabImage.pull

      Gitlab::Util.section_end
    end
  end
end
