require 'docker'
require_relative '../docker_operations.rb'
require_relative '../build/qa.rb'
require_relative '../build/check.rb'
require_relative '../build/info.rb'
require_relative '../build/image.rb'
require 'gitlab/qa'

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    location = Build::QA.get_gitlab_repo
    DockerOperations.build(location, Build::QA.gitlab_registry_image_address, Build::QA.latest_tag)
    Build::QA.tag_triggered_qa # Check if triggered QA and retag if necessary
  end

  namespace :push do
    desc "Push stable version of QA"
    task :stable do
      Build::Image.authenticate
      Build::QA.tag_and_push_to_dockerhub(Build::Info.docker_tag)
    end

    desc "Push rc version of QA"
    task :rc do
      if Build::Check.add_rc_tag?
        Build::Image.authenticate
        Build::QA.tag_and_push_to_dockerhub('rc')
      end
    end

    desc "Push nightly version of QA"
    task :nightly do
      if Build::Check.add_nightly_tag?
        Build::Image.authenticate
        Build::QA.tag_and_push_to_dockerhub('nightly')
      end
    end

    desc "Push latest version of QA"
    task :latest do
      if Build::Check.add_latest_tag?
        Build::Image.authenticate
        Build::QA.tag_and_push_to_dockerhub('latest')
      end
    end

    desc "Push triggered version of QA to GitLab Registry"
    task :triggered do
      Build::Image.authenticate('gitlab-ci-token', ENV['CI_JOB_TOKEN'], ENV['CI_REGISTRY'])
      Build::QA.tag_and_push_to_gitlab_registry(ENV['IMAGE_TAG'])
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
      Gitlab::QA::Scenario
        .const_get(task)
        .perform(Build::Info.gitlab_registry_image_address(tag: ENV['IMAGE_TAG']))
    end
  end
end
