require 'docker'

require_relative '../build/check'
require_relative '../build/gitlab_image'
require_relative '../build/info/ci'
require_relative '../build/info/docker'
require_relative '../docker_operations'
require_relative '../util'

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Gitlab::Util.section('docker:build:image') do
        Build::GitlabImage.write_release_file
        location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
        DockerOperations.build(
          location,
          Build::GitlabImage.gitlab_registry_image_address,
          'latest'
        )
      end
    end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    # Only runs on dev.gitlab.org
    task :staging do
      Gitlab::Util.section('docker:push:staging') do
        Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info::Docker.tag)

        # Also tag with CI_COMMIT_REF_SLUG so that manual testing using Docker
        # can use the same image name/tag.
        Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info::CI.commit_ref_slug)
      end
    end

    task :stable do
      Gitlab::Util.section('docker:push:stable') do
        if Gitlab::Util.get_env('USE_SKOPEO_FOR_DOCKER_RELEASE') == 'true'
          Build::GitlabImage.copy_image_to_dockerhub(Build::Info::Docker.tag)
        else
          Build::GitlabImage.tag_and_push_to_dockerhub(Build::Info::Docker.tag)
        end
      end
    end

    # Special tags
    task :nightly do
      next unless Build::Check.is_nightly?

      Gitlab::Util.section('docker:push:nightly') do
        if Gitlab::Util.get_env('USE_SKOPEO_FOR_DOCKER_RELEASE') == 'true'
          Build::GitlabImage.copy_image_to_dockerhub('nightly')
        else
          Build::GitlabImage.tag_and_push_to_dockerhub('nightly')
        end
      end
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      next unless Build::Check.is_latest_tag?

      Gitlab::Util.section('docker:push:rc') do
        if Gitlab::Util.get_env('USE_SKOPEO_FOR_DOCKER_RELEASE') == 'true'
          Build::GitlabImage.copy_image_to_dockerhub('rc')
        else
          Build::GitlabImage.tag_and_push_to_dockerhub('rc')
        end
      end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      next unless Build::Check.is_latest_stable_tag?

      Gitlab::Util.section('docker:push:latest') do
        if Gitlab::Util.get_env('USE_SKOPEO_FOR_DOCKER_RELEASE') == 'true'
          Build::GitlabImage.copy_image_to_dockerhub('latest')
        else
          Build::GitlabImage.tag_and_push_to_dockerhub('latest')
        end
      end
    end

    desc "Push triggered Docker Image to GitLab Registry"
    task :triggered do
      Gitlab::Util.section('docker:push:triggered') do
        Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info::Docker.tag)

        # Also tag with CI_COMMIT_REF_SLUG so that manual testing using Docker
        # can use the same image name/tag.
        Build::GitlabImage.tag_and_push_to_gitlab_registry(Build::Info::CI.commit_ref_slug)
      end
    end
  end

  desc "Pull Docker Image from Registry"
  namespace :pull do
    task :staging do
      if Gitlab::Util.get_env('USE_SKOPEO_FOR_DOCKER_RELEASE') == 'true'
        puts "USE_SKOPEO_FOR_DOCKER_RELEASE is set. So skipping pulling image."
        next
      end

      Gitlab::Util.section('docker:pull:staging') do
        DockerOperations.authenticate("gitlab-ci-token", Gitlab::Util.get_env("CI_JOB_TOKEN"), Gitlab::Util.get_env('CI_REGISTRY'))
        Build::GitlabImage.pull
      end
    end
  end
end
