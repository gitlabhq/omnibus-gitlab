require_relative 'trigger'

module Build
  class QATrigger
    extend Trigger

    QA_PROJECT_PATH = 'gitlab-org/gitlab-qa'.freeze

    def self.get_project_path
      QA_PROJECT_PATH
    end

    def self.get_params(image: nil)
      {
        "ref" => ENV['QA_BRANCH'] || 'master',
        "token" => ENV['QA_TRIGGER_TOKEN'],
        "variables[RELEASE]" => image,
        "variables[TRIGGERED_USER]" => ENV["TRIGGERED_USER"] || ENV["GITLAB_USER_NAME"],
        "variables[TRIGGER_SOURCE]" => ENV['CI_JOB_URL'],
        "variables[TOP_UPSTREAM_SOURCE_PROJECT]" => ENV['TOP_UPSTREAM_SOURCE_PROJECT'],
        "variables[TOP_UPSTREAM_SOURCE_JOB]" => ENV['TOP_UPSTREAM_SOURCE_JOB'],
        "variables[TOP_UPSTREAM_SOURCE_SHA]" => ENV['TOP_UPSTREAM_SOURCE_SHA']
      }
    end

    def self.get_access_token
      ENV['GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN']
    end
  end
end
