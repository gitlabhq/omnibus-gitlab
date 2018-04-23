# This script is a temporary workaround to trigger all our release jobs in one
# click. This saves our RMs from having to trigger releases to each OS
# individually.
# Native support for this is requested in https://gitlab.com/gitlab-org/gitlab-ce/issues/28741
# and this script will be removed when that is implemented.

require 'net/http'
require 'json'

stage = ARGV[0]

uri = URI("https://dev.gitlab.org/api/v4/projects/#{ENV['CI_PROJECT_ID']}/pipelines/#{ENV['CI_PIPELINE_ID']}/jobs?scope[]=manual&scope[]=created")
req = Net::HTTP::Get.new(uri)
req['PRIVATE-TOKEN'] = ENV['RELEASE_TRIGGER_TOKEN']
http = Net::HTTP.new(uri.hostname, uri.port)
http.use_ssl = true
res = http.request(req)
output = JSON.parse(res.body)
release_jobs = output.select { |item| item['stage'] == stage }
failed = []
release_jobs.each do |job|
  begin
    post_uri = URI("https://dev.gitlab.org/api/v4/projects/#{ENV['CI_PROJECT_ID']}/jobs/#{job['id']}/play")
    post_req = Net::HTTP::Post.new(post_uri)
    post_req['PRIVATE-TOKEN'] = ENV['RELEASE_TRIGGER_TOKEN']
    post_http = Net::HTTP.new(post_uri.hostname, post_uri.port)
    post_http.use_ssl = true
    post_http.request(post_req)
    puts "Played job: #{job['name']}"
  rescue StandardError
    failed << job['name']
    next
  end
end

unless failed.empty?
  puts "Failed jobs"
  puts failed.join(", ")
end
