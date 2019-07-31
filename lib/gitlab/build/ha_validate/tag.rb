require_relative '../trigger'
require_relative '../info'
require_relative "../../util.rb"

module Build
  class HA
    class ValidateTag
      extend Trigger

      PROJECT_PATH = 'gitlab-org/distribution/gitlab-provisioner'.freeze

      def self.get_project_path
        PROJECT_PATH
      end

      def self.package_url
        "https://downloads-packages.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_#{version}_amd64.deb"
      end

      def self.get_params(image: nil)
        qa_image = image || "dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ee-qa:#{version.partition(/\.\d+$/).first}"
        {
          'ref' => 'master',
          'token' => Gitlab::Util.get_env('HA_VALIDATE_TOKEN'),
          'variables[QA_IMAGE]' => qa_image,
          'variables[PACKAGE_URL]' => package_url
        }
      end

      def self.get_access_token
        Gitlab::Util.get_env('GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN')
      end

      def self.version
        Gitlab::Util.get_env('CI_COMMIT_TAG').tr('+', '-')
      end
    end
  end
end
