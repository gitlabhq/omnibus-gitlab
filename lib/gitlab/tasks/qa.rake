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
    edition = Build::Info.edition
    DockerOperations.build(location, "gitlab/gitlab-qa", "#{edition}-latest")
    Build::Image.tag_triggered_qa # Check if triggered QA and retag if necessary
  end

  namespace :push do
    desc "Push stable version of QA"
    task :stable do
      Build::Image.authenticate
      Build::Image.push_to_dockerhub(Build::Info.docker_tag, "qa")
    end

    desc "Push rc version of QA"
    task :rc do
      if Build::Check.add_rc_tag?
        Build::Image.authenticate
        Build::Image.push_to_dockerhub("#{Build::Info.edition}-rc", "qa")
      end
    end

    desc "Push nightly version of QA"
    task :nightly do
      if Build::Check.add_nightly_tag?
        Build::Image.authenticate
        Build::Image.push_to_dockerhub("#{Build::Info.edition}-nightly", "qa")
      end
    end

    desc "Push latest version of QA"
    task :latest do
      if Build::Check.add_latest_tag?
        Build::Image.authenticate
        Build::Image.push_to_dockerhub("#{Build::Info.edition}-latest", "qa")
      end
    end
  end

  desc "Run QA tests"
  task test: "qa:build" do # Requires the QA image to be built first
    release_package = Build::Info.package

    # Get the docker image which was built on the previous stage of pipeline
    image = "#{ENV['CI_REGISTRY_IMAGE']}/#{release_package}:#{ENV['IMAGE_TAG']}"

    [
      "Test::Instance::Image",         # Test whether instance starts correctly
      "Test::Omnibus::Image",          # Test whether image works correctly
      "Test::Omnibus::Upgrade",        # Test whether upgrade is done
      "Test::Integration::Mattermost"  # Test whether image works correctly with Mattermost
    ].each do |task|
      Gitlab::QA::Scenario
        .const_get(task)
        .perform(image)
    end
  end
end
