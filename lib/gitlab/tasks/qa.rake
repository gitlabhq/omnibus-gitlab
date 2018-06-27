require 'docker'
require_relative '../docker_operations'
require_relative '../build/qa'
require_relative '../build/check'
require_relative '../build/info'
require_relative '../build/gitlab_image'
require_relative '../build/qa_image'
require_relative '../build/qa_trigger'
require_relative '../build/ha_validate'

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    DockerOperations.build(
      Build::QA.get_gitlab_repo,
      Build::QAImage.gitlab_registry_image_address,
      'latest'
    )
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
      Build::QAImage.tag_and_push_to_dockerhub(Build::Info.gitlab_version, initial_tag: 'latest')
    end

    desc "Push rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      if Build::Check.add_rc_tag?
        Build::QAImage.tag_and_push_to_dockerhub('rc', initial_tag: 'latest')
      end
    end

    desc "Push nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      if Build::Check.add_nightly_tag?
        Build::QAImage.tag_and_push_to_dockerhub('nightly', initial_tag: 'latest')
      end
    end

    desc "Push latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      if Build::Check.add_latest_tag?
        Build::QAImage.tag_and_push_to_dockerhub('latest', initial_tag: 'latest')
      end
    end

    desc "Push triggered version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :triggered do
      Build::QAImage.tag_and_push_to_gitlab_registry(ENV['IMAGE_TAG'])
    end
  end

  desc "Run QA tests"
  task :test do
    image_address = Build::GitlabImage.gitlab_registry_image_address(tag: ENV['IMAGE_TAG'])
    Build::QATrigger.invoke!(image: image_address).wait!
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
