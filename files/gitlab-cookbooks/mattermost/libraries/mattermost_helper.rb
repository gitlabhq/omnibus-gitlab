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
      app_id, app_secret = o.stdout.lines.last.chomp.split(" ")

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

  def self.get_env_variables(node) # rubocop:disable Metrics/AbcSize (disabled because it is false positive)
    {
      'MM_SERVICESETTINGS_SITEURL' => node['mattermost']['service_site_url'].to_s,
      'MM_SERVICESETTINGS_LISTENADDRESS' => "#{node['mattermost']['service_address']}:#{node['mattermost']['service_port']}",
      'MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS' => node['mattermost']['service_allowed_untrusted_internal_connections'],
      'MM_SERVICESETTINGS_ENABLEAPITEAMDELETION' => node['mattermost']['service_enable_api_team_deletion'].to_s,
      'MM_TEAMSETTINGS_SITENAME' => node['mattermost']['team_site_name'].to_s,
      'MM_SQLSETTINGS_DRIVERNAME' => node['mattermost']['sql_driver_name'],
      'MM_SQLSETTINGS_DATASOURCE' => node['mattermost']['sql_data_source'].to_s,
      'MM_SQLSETTINGS_ATRESTENCRYPTKEY' => node['mattermost']['sql_at_rest_encrypt_key'].to_s,
      'MM_LOGSETTINGS_FILELOCATION' => (node['mattermost']['log_file_directory']).to_s,
      'MM_FILESETTINGS_DIRECTORY' => node['mattermost']['file_directory'].to_s,
      'MM_GITLABSETTINGS_ENABLE' => node['mattermost']['gitlab_enable'].to_s,
      'MM_GITLABSETTINGS_SECRET' => node['mattermost']['gitlab_secret'].to_s,
      'MM_GITLABSETTINGS_ID' => node['mattermost']['gitlab_id'].to_s,
      'MM_GITLABSETTINGS_SCOPE' => node['mattermost']['gitlab_scope'].to_s,
      'MM_GITLABSETTINGS_AUTHENDPOINT' => node['mattermost']['gitlab_auth_endpoint'].to_s,
      'MM_GITLABSETTINGS_TOKENENDPOINT' => node['mattermost']['gitlab_token_endpoint'].to_s,
      'MM_GITLABSETTINGS_USERAPIENDPOINT' => node['mattermost']['gitlab_user_api_endpoint'].to_s,
      'MM_PLUGINSETTINGS_DIRECTORY' => node['mattermost']['plugin_directory'].to_s,
      'MM_PLUGINSETTINGS_CLIENTDIRECTORY' => node['mattermost']['plugin_client_directory'].to_s
    }
  end
end unless defined?(MattermostHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
