require 'docker'
require_relative '../docker_operations'
require_relative '../build/qa'
require_relative '../build/check'
require_relative '../build/info'
require_relative '../build/gitlab_image'
require_relative '../build/qa_image'
require_relative '../build/qa_trigger'
require_relative '../build/ha_validate'
require_relative "../util.rb"

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    DockerOperations.build(
      Build::QA.get_gitlab_repo,
      Build::QAImage.gitlab_registry_image_address,
      'latest',
      dockerfile: 'qa/Dockerfile'
    )
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable or auto-deploy version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      tag = Build::Check.is_auto_deploy? ? Build::Info.major_minor_version_and_rails_ref : Build::Info.gitlab_version
      Build::QAImage.tag_and_push_to_gitlab_registry(tag)
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.commit_sha)
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
      Build::QAImage.tag_and_push_to_dockerhub(Build::Info.gitlab_version, initial_tag: 'latest')
    end

    desc "Push rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      Build::QAImage.tag_and_push_to_dockerhub('rc', initial_tag: 'latest') if Build::Check.is_latest_tag?
    end

    desc "Push nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Build::QAImage.tag_and_push_to_dockerhub('nightly', initial_tag: 'latest') if Build::Check.is_nightly?
    end

    desc "Push latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      Build::QAImage.tag_and_push_to_dockerhub('latest', initial_tag: 'latest') if Build::Check.is_latest_stable_tag?
    end

    desc "Push triggered version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :triggered do
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.docker_tag)
    end
  end

  desc "Run QA tests"
  task :test do
    image_address = Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)
    Build::QATrigger.invoke!(image: image_address, post_comment: true).wait!
  end

  namespace :ha do
    desc "Validate HA setup"
    task :validate do
      Build::HA::ValidateTrigger.invoke!.wait!
    end

    desc 'Validate nightly build'
    task :nightly do
      Build::HA::ValidateNightly.invoke!.wait!
    end

    desc 'Validate tagged build'
    task :tag do
      Build::HA::ValidateTag.invoke!
    end
  end
end
