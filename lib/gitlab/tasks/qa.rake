require 'docker'
require_relative '../docker_operations'
require_relative '../build/qa'
require_relative '../build/check'
require_relative '../build/info'
require_relative '../build/gitlab_image'
require_relative '../build/qa_image'
require 'gitlab/qa'

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
    desc "Push stable version of QA"
    task :stable do
      # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
      Build::QAImage.tag_and_push_to_gitlab_registry(Build::Info.gitlab_version)
      Build::QAImage.tag_and_push_to_dockerhub(Build::Info.gitlab_version, initial_tag: 'latest')
    end

    desc "Push rc version of QA"
    task :rc do
      if Build::Check.add_rc_tag?
        Build::QAImage.tag_and_push_to_dockerhub('rc', initial_tag: 'latest')
      end
    end

    desc "Push nightly version of QA"
    task :nightly do
      if Build::Check.add_nightly_tag?
        Build::QAImage.tag_and_push_to_dockerhub('nightly', initial_tag: 'latest')
      end
    end

    desc "Push latest version of QA"
    task :latest do
      if Build::Check.add_latest_tag?
        Build::QAImage.tag_and_push_to_dockerhub('latest', initial_tag: 'latest')
      end
    end

    desc "Push triggered version of QA to GitLab Registry"
    task :triggered do
      Build::QAImage.tag_and_push_to_gitlab_registry(ENV['IMAGE_TAG'])
    end
  end

  desc "Run QA tests"
  task test: ["qa:build", "qa:push:triggered"] do # Requires the QA image to be built and pushed first
    tests = [
      "Test::Instance::Image",         # Test whether instance starts correctly
      "Test::Omnibus::Image",          # Test whether image works correctly
      "Test::Omnibus::Upgrade",        # Test whether upgrade is done
      "Test::Integration::Mattermost"  # Test whether image works correctly with Mattermost
    ]

    tests.push('Test::Integration::Geo') if Build::Check.is_ee?

    tests.each do |task|
      # Get the docker image which was built on the previous stage of pipeline
      image_address = Build::GitlabImage.gitlab_registry_image_address(tag: ENV['IMAGE_TAG'])
      $stdout.puts "Running Gitlab::QA::Scenario::#{task} with the following image: #{image_address}"
      Gitlab::QA::Scenario.const_get(task).perform(image_address)
    end
  end
end
