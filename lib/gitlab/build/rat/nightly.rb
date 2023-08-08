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
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('RAT_TRIGGER_TOKEN'),
          'variables[REFERENCE_ARCHITECTURE]' => Gitlab::Util.get_env('RAT_REFERENCE_ARCHITECTURE') || 'omnibus-gitlab-mrs',
          'variables[NIGHTLY]' => "true",
          'variables[PACKAGE_VERSION]' => Build::Info::Package.name_version,
          'variables[QA_IMAGE]' => Gitlab::Util.get_env('QA_IMAGE') || image || 'gitlab/gitlab-ee-qa:nightly'
        }
      end

      def self.get_access_token
        # Default to "Multi-pipeline (from 'dev/gitlab/omnibus-gitlab' 'RAT-*' jobs)" at https://gitlab.com/gitlab-org/distribution/reference-architecture-tester/-/settings/access_tokens
        Gitlab::Util.get_env('RAT_PROJECT_ACCESS_TOKEN')
      end
    end
  end
end
