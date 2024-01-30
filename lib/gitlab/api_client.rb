require 'gitlab'

require_relative 'build/info/ci'
require_relative 'build/info/secrets'

module Gitlab
  class APIClient
    def initialize(endpoint = Build::Info::CI.api_v4_url, token = Build::Info::Secrets.api_token)
      @client = ::Gitlab::Client.new(endpoint: endpoint, private_token: token)
    end

    def get_job_id(job_name, project_id: Build::Info::CI.project_id, pipeline_id: Build::Info::CI.pipeline_id)
      jobs = @client.pipeline_jobs(project_id, pipeline_id).auto_paginate

      jobs.find { |j| j.name == job_name }&.id
    end
  end
end
