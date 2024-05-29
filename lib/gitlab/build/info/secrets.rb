require_relative '../../util'

module Build
  class Info
    class Secrets
      class << self
        def api_token(scope: 'reporter')
          Gitlab::Util.get_env("GITLAB_API_#{scope.upcase}_TOKEN")
        end

        def ci_job_token
          Build::Info::CI.job_token
        end
      end
    end
  end
end
