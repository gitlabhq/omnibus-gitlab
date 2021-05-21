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

      def self.omnibus_gitlab_path
        CGI.escape(Build::Info::OMNIBUS_PROJECT_MIRROR_PATH)
      end

      def self.get_params(image: nil)
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('RAT_TRIGGER_TOKEN'),
          'variables[REFERENCE_ARCHITECTURE]' => 'omnibus-gitlab-mrs',
          'variables[PACKAGE_URL]' => Gitlab::Util.get_env('PACKAGE_URL') || Build::Info.package_download_url,
          'variables[QA_IMAGE]' => Gitlab::Util.get_env('QA_IMAGE') || image || 'gitlab/gitlab-ee-qa:nightly'
        }
      end

      def self.get_access_token
        Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
      end
    end
  end
end
