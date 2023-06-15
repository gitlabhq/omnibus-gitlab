require_relative '../../util'
require_relative '../../api_client'
require_relative '../check'

module Build
  class Info
    class CI
      class << self
        def branch_name
          Gitlab::Util.get_env('CI_COMMIT_BRANCH')
        end

        def tag_name
          Gitlab::Util.get_env('CI_COMMIT_TAG')
        end

        def project_id
          Gitlab::Util.get_env('CI_PROJECT_ID')
        end

        def pipeline_id
          Gitlab::Util.get_env('CI_PIPELINE_ID')
        end

        def job_id
          Gitlab::Util.get_env('CI_JOB_ID')
        end

        def job_token
          Gitlab::Util.get_env('CI_JOB_TOKEN')
        end

        def api_v4_url
          Gitlab::Util.get_env('CI_API_V4_URL')
        end
      end
    end
  end
end
