#!/usr/bin/env ruby
require 'omnibus'

Omnibus.load_configuration('omnibus.rb')

require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"

puts "#{Omnibus::BuildVersion.semver}-#{Gitlab::BuildIteration.new.build_iteration}"
