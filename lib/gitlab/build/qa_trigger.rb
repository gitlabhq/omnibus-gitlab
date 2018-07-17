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
        "ref" => "master",
        "token" => ENV['QA_TRIGGER_TOKEN'],
        "variables[RELEASE]" => image,
        "variables[TRIGGERED_USER]" => ENV["TRIGGERED_USER"] || ENV["GITLAB_USER_NAME"],
        "variables[TRIGGER_SOURCE]" => "https://gitlab.com/gitlab-org/omnibus-gitlab/-/jobs/#{ENV['CI_JOB_ID']}",
        "variables[UPSTREAM_TRIGGER_SOURCE]" => ENV['TRIGGER_SOURCE']
      }
    end

    def self.get_access_token
      ENV['QA_ACCESS_TOKEN']
    end
  end
end
