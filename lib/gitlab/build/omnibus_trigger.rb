require_relative 'trigger'

module Build
  class OmnibusTrigger
    extend Trigger

    OMNIBUS_PROJECT_PATH = 'gitlab-org/omnibus-gitlab'.freeze

    def self.get_project_path
      OMNIBUS_PROJECT_PATH
    end

    def self.get_params(image: nil)
      {
        "ref" => ENV["CI_COMMIT_REF_NAME"],
        "token" => ENV["BUILD_TRIGGER_TOKEN"],
        "variables[ALTERNATIVE_SOURCES]" => true,
        "variables[IMAGE_TAG]" => "omnibus-#{ENV['CI_COMMIT_SHA']}",
        "variables[ee]" => ENV["ee"] || "false",
        "variables[TRIGGERED_USER]" => ENV["GITLAB_USER_NAME"],
        "variables[TRIGGER_SOURCE]" => "https://gitlab.com/gitlab-org/omnibus-gitlab/-/jobs/#{ENV['CI_JOB_ID']}"

      }
    end

    def self.get_access_token
      ENV['QA_ACCESS_TOKEN']
    end
  end
end
