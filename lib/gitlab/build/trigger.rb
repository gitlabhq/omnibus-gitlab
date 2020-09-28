require 'net/http'
require 'json'
require 'cgi'

require_relative "../util.rb"

module Build
  module Trigger
    def invoke!(image: nil, post_comment: false)
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
        Build::Trigger::CommitComment.post!(pipeline_url, get_access_token) if post_comment

        puts "Waiting for downstream pipeline status: #{pipeline_url}\n"
        Build::Trigger::Pipeline.new(pipeline_id, get_project_path, get_access_token)
      end
    end

    class CommitComment
      def self.post!(pipeline_url, access_token)
        unless Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA')
          puts "The 'TOP_UPSTREAM_SOURCE_SHA' environment variable is missing, cannot post a comment on a missing upstream commit."
          return
        end

        top_upstream_source_sha = Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA')

        unless Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT')
          puts "The 'TOP_UPSTREAM_SOURCE_PROJECT' environment variable is missing, cannot post a comment on the upstream #{top_upstream_source_sha} commit."
          return
        end

        top_upstream_source_project = Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT')

        comment = "The [`#{Gitlab::Util.get_env('CI_JOB_NAME')}`](#{Gitlab::Util.get_env('CI_JOB_URL')}) job from pipeline #{Gitlab::Util.get_env('CI_PIPELINE_URL')} triggered #{pipeline_url} downstream."
        uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(top_upstream_source_project)}/repository/commits/#{top_upstream_source_sha}/comments")
        request = Net::HTTP::Post.new(uri)
        request['PRIVATE-TOKEN'] = access_token
        request.set_form_data('note' => comment)
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response
        when Net::HTTPClientError, Net::HTTPServerError
          puts "Comment posting failed! The response from the comment post is: #{response}"
        else
          puts "The following comment was posted on https://gitlab.com/#{top_upstream_source_project}/commit/#{top_upstream_source_sha}:\n"
          puts comment
        end
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
            raise "Pipeline did not succeed!"
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

        JSON.parse(res.body)['status'].to_s.to_sym
      rescue JSON::ParserError
        # Ignore GitLab API hiccups. If GitLab is really down, we'll hit the job
        # timeout anyway.
        :running
      end
    end
  end
end
