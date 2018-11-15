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
        "variables[COMPILE_ASSETS]" => ENV['COMPILE_ASSETS'],
        "variables[IMAGE_TAG]" => "omnibus-#{ENV['CI_COMMIT_SHA']}",
        "variables[ee]" => ENV["ee"] || "false",
        "variables[TRIGGERED_USER]" => ENV["TRIGGERED_USER"] || ENV["GITLAB_USER_NAME"],
        "variables[TRIGGER_SOURCE]" => ENV['CI_JOB_URL'],
        "variables[TOP_UPSTREAM_SOURCE_PROJECT]" => ENV['TOP_UPSTREAM_SOURCE_PROJECT'],
        "variables[TOP_UPSTREAM_SOURCE_JOB]" => ENV['TOP_UPSTREAM_SOURCE_JOB'],
        "variables[TOP_UPSTREAM_SOURCE_SHA]" => ENV['TOP_UPSTREAM_SOURCE_SHA'],
        "variables[QA_BRANCH]" => ENV['QA_BRANCH'] || 'master'
      }
    end

    def self.get_access_token
      ENV['GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN']
    end
  end
end
