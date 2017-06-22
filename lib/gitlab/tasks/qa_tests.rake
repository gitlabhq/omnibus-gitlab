#!/usr/bin/env ruby

require 'gitlab/qa'
require_relative '../build.rb'

namespace :trigger do
  desc "Run QA tests when triggered"
  task :qa => "docker:build:qa" do  # Requires the QA image to be built first
    release_package = Build.package
    edition = release_package.gsub('gitlab-', '').strip # Return ce/ee

    # Get the docker image which was built on the previous stage of pipeline
    image = "registry.gitlab.com/omnibus-gitlab/#{release_package}:#{ENV['IMAGE_TAG']}"

    [
      Test::Instance::Image, # Test whether instance starts correctly
      Test::Omnibus::Image,  # Test whether image works correctly
      Test::Omnibus::Upgrade # Test whether upgrade is done
    ].each do |task|
      Gitlab::QA::Scenario
        .const_get(task)
        .perform([edition.upcase, image])
    end
  end
end

