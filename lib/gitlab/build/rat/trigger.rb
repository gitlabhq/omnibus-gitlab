require_relative '../trigger'
require_relative '../info'
require_relative "../../util"
require 'cgi'

module Build
  class RAT
    class TriggerPipeline
      extend Trigger

      PROJECT_PATH = 'gitlab-org/distribution/reference-architecture-tester'.freeze

      def self.get_project_path
        PROJECT_PATH
      end

      def self.get_params(image: nil)
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('RAT_TRIGGER_TOKEN'),
          'variables[REFERENCE_ARCHITECTURE]' => Gitlab::Util.get_env('RAT_REFERENCE_ARCHITECTURE') || 'omnibus-gitlab-mrs',
          'variables[PACKAGE_URL]' => Gitlab::Util.get_env('PACKAGE_URL') || Build::Info.triggered_build_package_url,
          'variables[QA_IMAGE]' => Gitlab::Util.get_env('QA_IMAGE') || image || "registry.gitlab.com/#{Gitlab::Util.get_env('CI_PROJECT_PATH')}/gitlab-ee-qa:#{Build::Info.docker_tag.gsub('.fips', '')}"
        }
      end

      def self.get_access_token
        # Default to "Multi-pipeline (from 'gitlab-org/omnibus-gitlab' 'RAT' job)" at https://gitlab.com/gitlab-org/distribution/reference-architecture-tester/-/settings/access_tokens
        Gitlab::Util.get_env('RAT_PROJECT_ACCESS_TOKEN') || Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
      end
    end
  end
end
