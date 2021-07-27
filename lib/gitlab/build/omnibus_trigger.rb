require_relative 'trigger'
require_relative 'info'
require_relative "../util"
require_relative "../version"

module Build
  class OmnibusTrigger
    extend Trigger

    def self.get_project_path
      Build::Info::OMNIBUS_PROJECT_MIRROR_PATH
    end

    def self.get_params(image: nil)
      {
        "ref" => Gitlab::Util.get_env("CI_COMMIT_REF_NAME"),
        "token" => Gitlab::Util.get_env("CI_JOB_TOKEN"),
        "variables[ALTERNATIVE_SOURCES]" => true,
        "variables[BUILDER_IMAGE_REVISION]" => Gitlab::Util.get_env('BUILDER_IMAGE_REVISION'),
        "variables[BUILDER_IMAGE_REGISTRY]" => Gitlab::Util.get_env('BUILDER_IMAGE_REGISTRY'),
        "variables[PUBLIC_BUILDER_IMAGE_REGISTRY]" => Gitlab::Util.get_env('PUBLIC_BUILDER_IMAGE_REGISTRY'),
        "variables[COMPILE_ASSETS]" => Gitlab::Util.get_env('COMPILE_ASSETS'),
        "variables[ee]" => Gitlab::Util.get_env("ee") || "false",
        "variables[TRIGGERED_USER]" => Gitlab::Util.get_env("TRIGGERED_USER") || Gitlab::Util.get_env("GITLAB_USER_NAME"),
        "variables[TRIGGER_SOURCE]" => Gitlab::Util.get_env('CI_JOB_URL'),
        "variables[TOP_UPSTREAM_SOURCE_PROJECT]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT'),
        "variables[TOP_UPSTREAM_SOURCE_JOB]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_JOB'),
        "variables[TOP_UPSTREAM_SOURCE_SHA]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA'),
        "variables[TOP_UPSTREAM_SOURCE_REF]" => Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF'),
        "variables[QA_BRANCH]" => Gitlab::Util.get_env('QA_BRANCH') || 'master'
      }.merge(version_params)
    end

    def self.version_params
      params = {}
      Gitlab::Version::COMPONENTS_ENV_VARS.values.uniq.each do |version|
        value = Gitlab::Util.get_env(version)
        params["variables[#{version}]"] = value if value
      end

      params
    end

    def self.get_access_token
      # Default to: "Multi-pipeline (from 'gitlab-org/omnibus-gitlab' 'Trigger:*e-package' job)" at https://gitlab.com/gitlab-org/omnibus-gitlab-mirror/-/settings/access_tokens
      Gitlab::Util.get_env('OMNIBUS_GITLAB_MIRROR_PROJECT_ACCESS_TOKEN') || Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
    end
  end
end
