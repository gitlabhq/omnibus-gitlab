require 'docker'
require 'json'

require_relative '../build/check'
require_relative '../build/gitlab_image'
require_relative '../build/info/components'
require_relative '../build/info/git'
require_relative '../build/qa'
require_relative '../build/qa_image'
require_relative '../docker_operations'
require_relative '../util'

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    edition_build_target = Build::Check.is_ee? ? 'ee' : 'foss'
    qa_build_target = Gitlab::Util.get_env('QA_BUILD_TARGET') || edition_build_target
    Gitlab::Util.section('qa:build') do
      DockerOperations.build(
        Build::QA.get_gitlab_repo,
        Build::QAImage.gitlab_registry_image_address,
        'latest',
        dockerfile: 'qa/Dockerfile',
        buildargs: JSON.generate({ QA_BUILD_TARGET: qa_build_target })
      )
    end
  end

  namespace :copy do
    desc "Copy nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Gitlab::Util.section('qa:copy:nightly') do
        Build::QAImage.copy_image_to_dockerhub('nightly') if Build::Check.is_nightly?
      end
    end

    desc "Copy stable version of gitlab-{ce,ee}-qa to the Omnibus registry and Docker Hub"
    task :stable do
      Gitlab::Util.section('qa:copy:stable') do
        # Using `Build::Info::Components::GitLabRails.version` allows to have
        # gitlab/gitlab-{ce,ee}-qa:X.Y.Z-{ce,ee} without the build number, as
        # opposed to using something like `Build::Info::Package.release_version`.
        Build::QAImage.copy_image_to_dockerhub(Build::Info::Components::GitLabRails.version)
      end
    end

    desc "Copy rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      Gitlab::Util.section('qa:copy:rc') do
        Build::QAImage.copy_image_to_dockerhub('rc') if Build::Check.is_latest_tag?
      end
    end

    desc "Copy latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      Gitlab::Util.section('qa:copy:latest') do
        Build::QAImage.copy_image_to_dockerhub('latest') if Build::Check.is_latest_stable_tag?
      end
    end
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      Gitlab::Util.section('qa:push:staging') do
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info::Components::GitLabRails.version)
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info::Git.commit_sha)
      end
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      Gitlab::Util.section('qa:push:stable') do
        # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info::Components::GitLabRails.version)
        Build::QAImage.tag_and_push_to_dockerhub(Build::Info::Components::GitLabRails.version, initial_tag: 'latest')
      end
    end

    desc "Push rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      Gitlab::Util.section('qa:push:rc') do
        Build::QAImage.tag_and_push_to_dockerhub('rc', initial_tag: 'latest') if Build::Check.is_latest_tag?
      end
    end

    desc "Push nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Gitlab::Util.section('qa:push:nightly') do
        Build::QAImage.tag_and_push_to_dockerhub('nightly', initial_tag: 'latest') if Build::Check.is_nightly?
      end
    end

    desc "Push latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      Gitlab::Util.section('qa:push:latest') do
        Build::QAImage.tag_and_push_to_dockerhub('latest', initial_tag: 'latest') if Build::Check.is_latest_stable_tag?
      end
    end
  end

  desc "Run QA letsencrypt tests"
  task :test_letsencrypt do
    Gitlab::Util.section('qa:test_letsencrypt') do
      Gitlab::Util.set_env_if_missing('CI_REGISTRY_IMAGE', 'registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror')
      image_address = Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info::Docker.tag)
      Dir.chdir('letsencrypt-test') do
        system({ 'IMAGE' => image_address }, './test.sh')
      end
    end
  end
end
