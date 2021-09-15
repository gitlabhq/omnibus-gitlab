require_relative 'trigger'
require_relative "../util.rb"

module Build
  class QATrigger
    extend Trigger

    QA_PROJECT_MIRROR_PATH = 'gitlab-org/gitlab-qa-mirror'.freeze

    def self.get_project_path
      QA_PROJECT_MIRROR_PATH
    end

    def self.get_params(image: nil)
      {
        "ref" => Gitlab::Util.get_env('QA_BRANCH') || 'master',
        "token" => Gitlab::Util.get_env('CI_JOB_TOKEN'),
        "variables[RELEASE]" => image,
        "variables[QA_IMAGE]" => Gitlab::Util.get_env('QA_IMAGE'),
        "variables[GITLAB_QA_OPTIONS]" => Gitlab::Util.get_env('GITLAB_QA_OPTIONS'),
        "variables[TRIGGERED_USER]" => Gitlab::Util.get_env("TRIGGERED_USER") || Gitlab::Util.get_env("GITLAB_USER_NAME"),
        "variables[TRIGGER_SOURCE]" => Gitlab::Util.get_env('CI_JOB_URL'),
        "variables[TOP_UPSTREAM_SOURCE_PROJECT]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT'),
        "variables[TOP_UPSTREAM_SOURCE_JOB]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_JOB'),
        "variables[TOP_UPSTREAM_SOURCE_SHA]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA'),
        'variables[TOP_UPSTREAM_SOURCE_REF]' => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF'),
        'variables[TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID]' => Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID'),
        'variables[TOP_UPSTREAM_MERGE_REQUEST_IID]' => Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_IID')
      }.compact
    end

    def self.get_access_token
      # Default to "Multi-pipeline (from 'gitlab-org/build/omnibus-gitlab-mirror' 'Trigger:qa-test' job)" at https://gitlab.com/gitlab-org/gitlab-qa-mirror/-/settings/access_tokens
      Gitlab::Util.get_env('GITLAB_QA_MIRROR_PROJECT_ACCESS_TOKEN') || Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
    end
  end
end
