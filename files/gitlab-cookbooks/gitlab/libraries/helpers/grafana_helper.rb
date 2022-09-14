require_relative 'authorizer_helper'
require_relative '../../../package/libraries/helpers/shell_out_helper'

class GrafanaHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{gitlab_external_url}/-/grafana/login/gitlab"
    app_name = 'GitLab Grafana'
    oauth_uid = Gitlab['grafana']['gitlab_application_id']
    oauth_secret = Gitlab['grafana']['gitlab_secret']

    o = query_gitlab_rails(redirect_uri, app_name, oauth_uid, oauth_secret)

    if o.exitstatus.zero?
      Gitlab['grafana']['register_as_oauth_app'] = false

      SecretsHelper.write_to_gitlab_secrets
      info('Updated the gitlab-secrets.json file.')
    else
      warn('Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.')
    end
  end
end
