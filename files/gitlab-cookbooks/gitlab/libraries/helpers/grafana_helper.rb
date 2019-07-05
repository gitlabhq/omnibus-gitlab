require_relative 'authorizer_helper'
require_relative '../../../package/libraries/helpers/shell_out_helper'

class GrafanaHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{gitlab_external_url}/-/grafana/login/gitlab"
    app_name = 'GitLab Grafana'

    o = query_gitlab_rails(redirect_uri, app_name)

    if o.exitstatus.zero?
      app_id, app_secret = o.stdout.lines.last.chomp.split(" ")

      Gitlab['grafana']['gitlab_secret'] = app_secret
      Gitlab['grafana']['gitlab_application_id'] = app_id

      SecretsHelper.write_to_gitlab_secrets
      info('Updated the gitlab-secrets.json file.')
    else
      warn('Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.')
    end
  end
end
