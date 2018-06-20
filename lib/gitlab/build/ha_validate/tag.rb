require_relative '../trigger'
require_relative '../info'

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
        qa_image = image || "gitlab/gitlab-ee-qa:#{version.partition(/\.\d+$/).first}"
        {
          'ref' => 'master',
          'token' => ENV['HA_VALIDATE_TOKEN'],
          'variables[QA_IMAGE]' =>  qa_image,
          'variables[PACKAGE_URL]' => package_url
        }
      end

      def self.get_access_token
        ENV['HA_VALIDATE_TOKEN']
      end

      def self.version
        ENV['CI_COMMIT_TAG'].tr('+', '-')
      end
    end
  end
end
