require 'net/http'
require 'json'
require 'cgi'

module Build
  module Trigger
    def invoke!(image: nil)
      uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(get_project_path)}/trigger/pipeline")
      params = get_params(image: image)
      res = Net::HTTP.post_form(uri, params)
      id = JSON.parse(res.body)['id']

      raise "Trigger failed! The response from the trigger is: #{res.body}" unless id

      puts "Triggered https://gitlab.com/#{get_project_path}/pipelines/#{id}"
      puts "Waiting for downstream pipeline status"
      Build::Trigger::Pipeline.new(id, get_project_path, get_access_token)
    end

    class Pipeline
      INTERVAL = 60 # seconds
      MAX_DURATION = 3600 * 3 # 3 hours

      def initialize(id, project_path, access_token)
        @start = Time.now.to_i
        @access_token = access_token
        @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(project_path)}/pipelines/#{id}")
      end

      def wait!
        loop do
          raise "Pipeline timed out after waiting for #{duration} minutes!" if timeout?

          case status
          when :created, :pending, :running
            print "."
            sleep INTERVAL
          when :success
            puts "Pipeline succeeded in #{duration} minutes!"
            break
          else
            raise "Pipeline did not succeed!"
          end

          STDOUT.flush
        end
      end

      def timeout?
        Time.now.to_i > (@start + MAX_DURATION)
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
