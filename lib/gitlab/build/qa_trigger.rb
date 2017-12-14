require 'net/http'
require 'json'
require 'cgi'

module Build
  QA_PROJECT_PATH = 'gitlab-org/gitlab-qa'.freeze

  class QATrigger
    TOKEN = ENV['QA_TRIGGER_TOKEN']

    def initialize(image: nil)
      # image denotes the GitLab CE/EE image against which tests are run
      # qa_image denotes the QA image on which the tests are run.
      @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(Build::QA_PROJECT_PATH)}/trigger/pipeline")
      @params = {
        "ref" => "master",
        "token" => TOKEN,
        "variables[RELEASE]" => image,
        "variables[TRIGGERED_USER]" => ENV["TRIGGERED_USER"] || ENV["GITLAB_USER_NAME"],
        "variables[TRIGGER_SOURCE]" => "https://gitlab.com/gitlab-org/omnibus-gitlab/-/jobs/#{ENV['CI_JOB_ID']}"
      }
    end

    def invoke!
      res = Net::HTTP.post_form(@uri, @params)
      id = JSON.parse(res.body)['id']

      raise "Trigger failed! The response from the trigger is: #{res.body}" unless id

      puts "Triggered https://gitlab.com/#{Build::QA_PROJECT_PATH}/pipelines/#{id}"
      puts "Waiting for downstream pipeline status"
      Build::QAPipeline.new(id)
    end
  end

  class QAPipeline
    INTERVAL = 60 # seconds
    MAX_DURATION = 3600 * 3 # 3 hours

    def initialize(id)
      @start = Time.now.to_i
      @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(Build::QA_PROJECT_PATH)}/pipelines/#{id}")
    end

    def wait!
      loop do
        raise "Pipeline timed out after waiting for #{duration} minutes!" if timeout?

        case status
        when :created, :pending, :running
          print "."
          sleep INTERVAL
        when :success
          puts "QA pipeline succeeded in #{duration} minutes!"
          break
        else
          raise "QA pipeline did not succeed!"
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
      req['PRIVATE-TOKEN'] = ENV['QA_ACCESS_TOKEN']

      res = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      JSON.parse(res.body)['status'].to_s.to_sym
    end
  end
end
