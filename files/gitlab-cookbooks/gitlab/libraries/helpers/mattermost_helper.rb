require_relative 'shell_out_helper'
require_relative 'authorizer_helper'

class MattermostHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def initialize(node, mattermost_user, mattermost_home)
    @node = node
    @mattermost_user = mattermost_user
    @mattermost_home = mattermost_home
    @config_file_path = File.join(@mattermost_home, 'config.json')
    @status = {}
  end

  def version
    return @status[:version] if @status.key?(:version)

    cmd = self.class.version_cmd(@config_file_path)
    result = self.class.do_shell_out(cmd, @mattermost_user, "/opt/gitlab/embedded/service/mattermost")

    if result.exitstatus == 0
      @status[:version] = result.stdout
    else
      @status[:version] = nil
    end
  end

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

  def self.version_cmd(path)
    "/opt/gitlab/embedded/bin/mattermost -config='#{path}' -version"
  end

  def self.upgrade_db_30(path, user, team_name)
    cmd = upgrade_db_30_cmd(path, team_name)
    result = do_shell_out(cmd, user, '/opt/gitlab/embedded/service/mattermost')
    result.exitstatus
  end

  def self.upgrade_db_30_cmd(path, team_name)
    "/opt/gitlab/embedded/bin/mattermost -config='#{path}' -upgrade_db_30 -confirm_backup='YES' -team_name='#{team_name}'"
  end
end
