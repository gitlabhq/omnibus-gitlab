require 'cgi'

require_relative '../../util'
require_relative '../info/package'
require_relative '../trigger'

module Build
  class RAT
    class TagPipeline
      extend Trigger

      PROJECT_PATH = 'gitlab-org/distribution/reference-architecture-tester'.freeze

      def self.get_project_path
        PROJECT_PATH
      end

      def self.get_params(image: nil)
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('RAT_TRIGGER_TOKEN'),
          'variables[REFERENCE_ARCHITECTURE]' => 'omnibus-gitlab-mrs',
          'variables[PRE_RELEASE]' => "true",
          'variables[PACKAGE_VERSION]' => Build::Info::Package.name_version,
          'variables[QA_IMAGE]' => Gitlab::Util.get_env('QA_IMAGE') || image || "dev.gitlab.org:5005/gitlab/gitlab-ee/gitlab-ee-qa:#{version.partition(/\.\d+$/).first}"
        }
      end

      def self.version
        Gitlab::Util.get_env('CI_COMMIT_TAG').tr('+', '-')
      end

      def self.get_access_token
        # Default to "Multi-pipeline (from 'dev/gitlab/omnibus-gitlab' 'RAT-*' jobs)" at https://gitlab.com/gitlab-org/distribution/reference-architecture-tester/-/settings/access_tokens
        Gitlab::Util.get_env('RAT_PROJECT_ACCESS_TOKEN')
      end
    end
  end
end
