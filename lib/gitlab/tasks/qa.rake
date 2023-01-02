require 'docker'
require_relative '../docker_operations'
require_relative '../build/qa'
require_relative '../build/check'
require_relative '../build/info'
require_relative '../build/gitlab_image'
require_relative '../build/qa_image'
require_relative '../build/rat'
require_relative "../util.rb"
require 'json'

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
    desc "Copy current QA image from GitLab rails registry to omnibus-gitlab registry"
    task :staging do
      Gitlab::Util.section('qa:copy:staging') do
        Build::QAImage.copy_image_to_omnibus_registry(Build::Info.gitlab_version)
        Build::QAImage.copy_image_to_omnibus_registry(Build::Info.commit_sha)
      end
    end

    desc "Copy nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Gitlab::Util.section('qa:copy:nightly') do
        Build::QAImage.copy_image_to_dockerhub('nightly') if Build::Check.is_nightly?
      end
    end
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      Gitlab::Util.section('qa:push:staging') do
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.commit_sha)
      end
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      Gitlab::Util.section('qa:push:stable') do
        # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
        Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
        Build::QAImage.tag_and_push_to_dockerhub(Build::Info.gitlab_version, initial_tag: 'latest')
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
      image_address = Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)
      Dir.chdir('letsencrypt-test') do
        system({ 'IMAGE' => image_address }, './test.sh')
      end
    end
  end

  namespace :rat do
    desc "Trigger a RAT pipeline"
    task :trigger do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::TriggerPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end

    desc "Trigger a RAT pipeline using nightly package"
    task :nightly do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::NightlyPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end

    desc "Trigger a RAT pipeline using tag package"
    task :tag do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::TagPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end
  end
end
