#!/usr/bin/env ruby
require 'omnibus'

Omnibus.load_configuration('omnibus.rb')

require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"

semver = Omnibus::BuildVersion.semver
if ENV['NIGHTLY'] && ENV['CI_PIPELINE_ID']
  semver = "#{semver}.#{ENV['CI_PIPELINE_ID']}"
end

puts "#{semver}-#{Gitlab::BuildIteration.new.build_iteration}"
