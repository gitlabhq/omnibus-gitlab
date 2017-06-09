#!/usr/bin/env ruby
require 'net/http'
require 'json'

uri = URI("https://gitlab.com/api/v4/projects/#{ENV['CI_PROJECT_ID']}/pipelines/#{ENV['CI_PIPELINE_ID']}/jobs")
req = Net::HTTP::Get.new(uri)
req['PRIVATE-TOKEN'] = ENV["TRIGGER_PRIVATE_TOKEN"]
http = Net::HTTP.new(uri.hostname, uri.port)
http.use_ssl = true
res = http.request(req)
output = JSON.parse(res.body)
id = output.find { |job| job['name'] == 'Trigger:package' }['id']
puts "#{ENV['CI_PROJECT_URL']}/builds/#{id}/artifacts/raw/pkg/ubuntu-xenial/gitlab.deb"
