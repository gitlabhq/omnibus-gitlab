require_relative '../../trigger'
require_relative '../../info'

module Build
  class Get
    class Geo
      class TriggerPipeline
        extend Trigger

        class <<self
          def get_project_path
            'gitlab-org/quality/gitlab-environment-toolkit-configs/Geo'
          end

          def get_access_token
            Gitlab::Util.get_env('GET_GEO_ACCESS_TOKEN')
          end

          def get_params(image: nil)
            {
              'ref' => 'master',
              'token' => Gitlab::Util.get_env('GET_GEO_QA_TRIGGER_TOKEN'),
              'variables[ENVIRONMENT_ACTION]' => 'tmp-env',
              'variables[GITLAB_DEB_DOWNLOAD_URL]' => Gitlab::Util.get_env('PACKAGE_URL') || Build::Info.triggered_build_package_url
            }
          end
        end
      end
    end
  end
end
