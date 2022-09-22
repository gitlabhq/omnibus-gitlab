require_relative '../trigger'
require_relative '../info'
require_relative "../../util"
require 'cgi'

module Build
  class RAT
    class NightlyPipeline
      extend Trigger

      PROJECT_PATH = 'gitlab-org/distribution/reference-architecture-tester'.freeze

      def self.get_project_path
        PROJECT_PATH
      end

      def self.get_params(image: nil)
        package_url = if Build::Check.use_system_ssl?
                        Build::Info.rpm_package_download_url
                      else
                        Build::Info.deb_package_download_url
                      end
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('RAT_TRIGGER_TOKEN'),
          'variables[REFERENCE_ARCHITECTURE]' => Gitlab::Util.get_env('RAT_REFERENCE_ARCHITECTURE') || 'omnibus-gitlab-mrs',
          'variables[PACKAGE_URL]' => Gitlab::Util.get_env('PACKAGE_URL') || package_url,
          'variables[QA_IMAGE]' => Gitlab::Util.get_env('QA_IMAGE') || image || 'gitlab/gitlab-ee-qa:nightly'
        }
      end

      def self.get_access_token
        # Default to "Multi-pipeline (from 'dev/gitlab/omnibus-gitlab' 'RAT-*' jobs)" at https://gitlab.com/gitlab-org/distribution/reference-architecture-tester/-/settings/access_tokens
        Gitlab::Util.get_env('RAT_PROJECT_ACCESS_TOKEN') || Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
      end
    end
  end
end
