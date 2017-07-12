require_relative 'authorizer_helper'

class MattermostHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{Gitlab['mattermost_external_url']}/signup/gitlab/complete\r\n#{Gitlab['mattermost_external_url']}/login/gitlab/complete"
    app_name = 'GitLab Mattermost'

    o = query_gitlab_rails(redirect_uri, app_name)

    app_id, app_secret = nil
    if o.exitstatus == 0
      app_id, app_secret = o.stdout.chomp.split(" ")

      Gitlab['mattermost']['gitlab_enable'] = true
      Gitlab['mattermost']['gitlab_secret'] = app_secret
      Gitlab['mattermost']['gitlab_id'] = app_id
      Gitlab['mattermost']['gitlab_scope'] = ""

      SecretsHelper.write_to_gitlab_secrets
      info('Updated the gitlab-secrets.json file.')
    else
      warn('Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.')
    end
  end
end
