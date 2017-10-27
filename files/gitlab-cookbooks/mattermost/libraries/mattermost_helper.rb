require_relative '../../gitlab/libraries/helpers/authorizer_helper'
require_relative '../../package/libraries/helpers/shell_out_helper'

class MattermostHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(MattermostHelper)` at the end of the class definition)
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{Gitlab['mattermost_external_url']}/signup/gitlab/complete\r\n#{Gitlab['mattermost_external_url']}/login/gitlab/complete"
    app_name = 'GitLab Mattermost'

    o = query_gitlab_rails(redirect_uri, app_name)

    if o.exitstatus.zero?
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
end unless defined?(MattermostHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
