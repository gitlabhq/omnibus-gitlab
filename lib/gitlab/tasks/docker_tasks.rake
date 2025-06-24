require 'docker'

require_relative '../build/check'
require_relative '../build/gitlab_image'
require_relative '../build/info/ci'
require_relative '../build/info/docker'
require_relative '../docker_operations'
require_relative '../docker_helper'
require_relative '../util'

namespace :docker do
  namespace :build do
    desc "Build Docker All in one image"
    task :image do
      Gitlab::Util.section('docker:build:image') do
        Build::GitlabImage.write_release_file
        location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))

        DockerHelper.authenticate(username: "gitlab-ci-token",
                                  password: Gitlab::Util.get_env('CI_JOB_TOKEN'),
                                  registry: Gitlab::Util.get_env('CI_REGISTRY'))

        dp_login = Gitlab::Util.get_env('DEPENDENCY_PROXY_LOGIN')

        if dp_login == 'true'
          puts "Logging in to dependency proxy"
          DockerHelper.authenticate(username: Gitlab::Util.get_env('CI_DEPENDENCY_PROXY_USER'),
                                    password: Gitlab::Util.get_env('CI_DEPENDENCY_PROXY_PASSWORD'),
                                    registry: Gitlab::Util.get_env('CI_DEPENDENCY_PROXY_SERVER'))
        else
          puts "Skipping login to dependency proxy (DEPENDENCY_PROXY_LOGIN=#{dp_login})"
        end

        build_args = []
        base_image = Gitlab::Util.get_env('UBUNTU_IMAGE')
        build_args << "BASE_IMAGE=#{base_image}" if base_image

        DockerHelper.build(location, Build::GitlabImage.gitlab_registry_image_address, Build::Info::Docker.arch_tag, buildargs: build_args)
      end
    end
  end

  desc "Push Docker Image to Registry"
  namespace :push do
    # Only runs on dev.gitlab.org
    task :staging do
      Gitlab::Util.section('docker:push:staging') do
        # As part of build, the image is already tagged and pushed  to GitLab
        # registry with `Build::Info::Docker.tag` as the tag. Also copy the
        # image with `CI_COMMIT_REF_SLUG` as the tag so that manual testing
        # using Docker can use the same image name/tag.
        Build::GitlabImage.copy_image_to_gitlab_registry(Build::Info::Docker.arch_tag(Build::Info::CI.commit_ref_slug))
      end
    end

    task :stable do
      Gitlab::Util.section('docker:push:stable') do
        Build::GitlabImage.copy_image_to_dockerhub(Build::Info::Docker.tag)

        next if Gitlab::Util.get_env('DISABLE_PUBLIC_IMAGE_UPLOAD') == 'true'

        Build::GitlabImage.copy_image_to_external_registry(
          Gitlab::Util.get_env('PUBLIC_IMAGE_ARCHIVE_REGISTRY'),
          Gitlab::Util.get_env('PUBLIC_IMAGE_ARCHIVE_REGISTRY_PATH'),
          Gitlab::Util.get_env('PUBLIC_IMAGE_ARCHIVE_REGISTRY_USERNAME'),
          Gitlab::Util.get_env('PUBLIC_IMAGE_ARCHIVE_REGISTRY_PASSWORD'),
          Build::Info::Docker.tag
        )
      end
    end

    # Special tags
    task :nightly do
      next unless Build::Check.is_nightly?

      Gitlab::Util.section('docker:push:nightly') do
        Build::GitlabImage.copy_image_to_dockerhub('nightly')
      end
    end

    # push as :rc tag, the :rc is always the latest tagged release
    task :rc do
      next unless Build::Check.is_latest_tag?

      Gitlab::Util.section('docker:push:rc') do
        Build::GitlabImage.copy_image_to_dockerhub('rc')
      end
    end

    # push as :latest tag, the :latest is always the latest stable release
    task :latest do
      next unless Build::Check.is_latest_stable_tag?

      Gitlab::Util.section('docker:push:latest') do
        Build::GitlabImage.copy_image_to_dockerhub('latest')
      end
    end

    desc "Push triggered Docker Image to GitLab Registry"
    task :triggered do
      Gitlab::Util.section('docker:push:triggered') do
        # As part of build, the image is already tagged and pushed with
        # `Build::Info::Docker.tag` as the tag. Also copy the image with
        # `CI_COMMIT_REF_SLUG` as the tag so that manual testing using Docker
        # can use the same image name/tag.
        Build::GitlabImage.copy_image_to_gitlab_registry(Build::Info::Docker.arch_tag(Build::Info::CI.commit_ref_slug))
      end
    end
  end

  desc "Combine images with different architectures to a single multiarch image"
  task :combine_images do
    Gitlab::Util.section('docker:combine_images') do
      DockerHelper.authenticate(username: "gitlab-ci-token",
                                password: Gitlab::Util.get_env('CI_JOB_TOKEN'),
                                registry: Gitlab::Util.get_env('CI_REGISTRY'))
      image = Build::GitlabImage.gitlab_registry_image_address
      tag = Build::Info::Docker.tag
      amd64_tag = Build::Info::Docker.arch_tag(arch: 'amd64')
      arm64_tag = Build::Info::Docker.arch_tag(arch: 'arm64')
      DockerHelper.combine_images(image, tag, [amd64_tag, arm64_tag])

      puts "Combined #{amd64_tag} and #{arm64_tag} tags to #{image}:#{tag}"
    end
  end
end
