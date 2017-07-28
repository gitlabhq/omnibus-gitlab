require 'docker'
require_relative '../docker_operations.rb'
require_relative '../build.rb'
require 'gitlab/qa'

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    location = Build.get_gitlab_repo
    edition = Build.edition
    DockerOperations.build(location, "gitlab/gitlab-qa", "#{edition}-latest")
    Build.tag_triggered_qa # Check if triggered QA and retag if necessary
  end

  namespace :push do
    desc "Push stable version of QA"
    task :stable do
      Build.authenticate
      Build.push_to_dockerhub(Build.docker_tag, "qa")
    end

    desc "Push rc version of QA"
    task :rc do
      if Build.add_rc_tag?
        Build.authenticate
        Build.push_to_dockerhub("#{Build.edition}-rc", "qa")
      end
    end

    desc "Push nightly version of QA"
    task :nightly do
      if Build.add_nightly_tag?
        Build.authenticate
        Build.push_to_dockerhub("#{Build.edition}-nightly", "qa")
      end
    end

    desc "Push latest version of QA"
    task :latest do
      if Build.add_latest_tag?
        Build.authenticate
        Build.push_to_dockerhub("#{Build.edition}-latest", "qa")
      end
    end
  end

  desc "Run QA tests"
  task test: "qa:build" do # Requires the QA image to be built first
    release_package = Build.package

    # Get the docker image which was built on the previous stage of pipeline
    image = "#{ENV['CI_REGISTRY_IMAGE']}/#{release_package}:#{ENV['IMAGE_TAG']}"

    [
      "Test::Instance::Image", # Test whether instance starts correctly
      "Test::Omnibus::Image",  # Test whether image works correctly
      "Test::Omnibus::Upgrade" # Test whether upgrade is done
    ].each do |task|
      Gitlab::QA::Scenario
        .const_get(task)
        .perform(image)
    end
  end
end
