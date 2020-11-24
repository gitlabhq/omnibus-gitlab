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
    Gitlab::Util.section_start('qa:build')

    DockerOperations.build(
      Build::QA.get_gitlab_repo,
      Build::QAImage.gitlab_registry_image_address,
      'latest',
      dockerfile: 'qa/Dockerfile'
    )

    Gitlab::Util.section_end
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable or auto-deploy version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      Gitlab::Util.section_start('qa:push:staging')

      tag = Build::Check.is_auto_deploy? ? Build::Info.major_minor_version_and_rails_ref : Build::Info.gitlab_version
      Build::QAImage.tag_and_push_to_gitlab_registry(tag)
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.commit_sha)

      Gitlab::Util.section_end
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      Gitlab::Util.section_start('qa:push:stable')

      # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
      Build::QAImage.tag_and_push_to_dockerhub(Build::Info.gitlab_version, initial_tag: 'latest')

      Gitlab::Util.section_end
    end

    desc "Push rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      Gitlab::Util.section_start('qa:push:rc')
      Build::QAImage.tag_and_push_to_dockerhub('rc', initial_tag: 'latest') if Build::Check.is_latest_tag?
      Gitlab::Util.section_end
    end

    desc "Push nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Gitlab::Util.section_start('qa:push:nightly')
      Build::QAImage.tag_and_push_to_dockerhub('nightly', initial_tag: 'latest') if Build::Check.is_nightly?
      Gitlab::Util.section_end
    end

    desc "Push latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      Gitlab::Util.section_start('qa:push:latest')
      Build::QAImage.tag_and_push_to_dockerhub('latest', initial_tag: 'latest') if Build::Check.is_latest_stable_tag?
      Gitlab::Util.section_end
    end

    desc "Push triggered version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :triggered do
      Gitlab::Util.section_start('qa:push:triggered')
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.docker_tag)
      Gitlab::Util.section_end
    end
  end

  desc "Run QA tests"
  task :test do
    Gitlab::Util.section_start('qa:test')

    image_address = Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)
    Build::QATrigger.invoke!(image: image_address, post_comment: true).wait!

    Gitlab::Util.section_end
  end

  namespace :ha do
    desc "Validate HA setup"
    task :validate do
      Gitlab::Util.section_start('qa:ha:validate')
      Build::HA::ValidateTrigger.invoke!.wait!(timeout: 3600 * 4)
      Gitlab::Util.section_end
    end

    desc 'Validate nightly build'
    task :nightly do
      Gitlab::Util.section_start('qa:ha:nightly')
      Build::HA::ValidateNightly.invoke!.wait!(timeout: 3600 * 4)
      Gitlab::Util.section_end
    end

    desc 'Validate tagged build'
    task :tag do
      Gitlab::Util.section_start('qa:ha:tag')
      Build::HA::ValidateTag.invoke!(timeout: 3600 * 4)
      Gitlab::Util.section_end
    end
  end
end
