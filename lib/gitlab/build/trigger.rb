require 'cgi'
require 'json'
require 'net/http'

require_relative '../util'

module Build
  module Trigger
    def invoke!(image: nil)
      uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(get_project_path)}/trigger/pipeline")
      params = get_params(image: image)
      params_without_token = params.dup
      params_without_token.delete('token')

      puts "Triggering downstream pipeline on #{get_project_path}"
      puts "with params #{params_without_token}"

      response = Net::HTTP.post_form(uri, params)
      response_body = JSON.parse(response.body)
      pipeline_id = response_body['id']
      pipeline_url = response_body['web_url']

      case response
      when Net::HTTPClientError, Net::HTTPServerError
        raise "Trigger failed! The response from the trigger is: #{response.message}: #{response.body}"
      else
        puts "Waiting for downstream pipeline status: #{pipeline_url}\n"
        Build::Trigger::Pipeline.new(pipeline_id, get_project_path, get_access_token)
      end
    end

    class Pipeline
      INTERVAL = 60 # seconds
      DEFAULT_MAX_DURATION = 3600 * 3 # 3 hours

      def initialize(id, project_path, access_token)
        @start = Time.now.to_i
        @access_token = access_token
        @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(project_path)}/pipelines/#{id}")
      end

      def wait!(timeout: DEFAULT_MAX_DURATION)
        loop do
          raise "Pipeline timed out after waiting for #{duration} minutes!" if timeout?(timeout)

          case status
          when :created, :pending, :running
            print "."
            sleep INTERVAL
          when :success
            puts "Pipeline succeeded in #{duration} minutes!"
            break
          when :scheduled
            puts "After #{duration} minutes, pipeline is currently paused and scheduled to continue later. Considering it a successful pipeline."
            break
          else
            puts "Received unhandled status: #{status}"
            raise "Pipeline did not succeed! [#{status}]"
          end

          STDOUT.flush
        end
      end

      def timeout?(max_duration)
        Time.now.to_i > (@start + max_duration)
      end

      def duration
        (Time.now.to_i - @start) / 60
      end

      def status
        req = Net::HTTP::Get.new(@uri)
        req['PRIVATE-TOKEN'] = @access_token

        res = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: true) do |http|
          http.request(req)
        end

        raise "Error fetching status: #{res.code} -- #{res.message}" unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body)['status'].to_s.to_sym
      rescue JSON::ParserError
        # Ignore GitLab API hiccups. If GitLab is really down, we'll hit the job
        # timeout anyway.
        :running
      end
    end
  end
end
