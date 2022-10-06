require_relative '../../trigger'
require_relative '../../info'

module Build
  class Get
    class Geo
      class TriggerPipeline
        extend Trigger

        class <<self
          def get_project_path
            'gitlab-org/geo-team/geo-ci'
          end

          def get_access_token
            Gitlab::Util.get_env('GET_GEO_ACCESS_TOKEN')
          end

          def get_params(image: nil)
            {
              'ref' => Gitlab::Util.get_env('GET_GEO_REF') || 'main',
              'token' => Gitlab::Util.get_env('GET_GEO_QA_TRIGGER_TOKEN'),
              'variables[ENVIRONMENT_ACTION]' => 'tmp-env',
              'variables[QA_IMAGE]' => Build::Info.qa_image,
              'variables[GITLAB_DEB_DOWNLOAD_URL]' => Gitlab::Util.get_env('PACKAGE_URL') || Build::Info.triggered_build_package_url
            }
          end
        end
      end
    end
  end
end
