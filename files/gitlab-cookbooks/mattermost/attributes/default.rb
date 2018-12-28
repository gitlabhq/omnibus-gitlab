#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['mattermost']['enable'] = false
default['mattermost']['username'] = 'mattermost'
default['mattermost']['group'] = 'mattermost'
default['mattermost']['uid'] = nil
default['mattermost']['gid'] = nil
default['mattermost']['home'] = '/var/opt/gitlab/mattermost'
default['mattermost']['database_name'] = 'mattermost_production'
default['mattermost']['env_directory'] = '/opt/gitlab/etc/mattermost/env'
default['mattermost']['env'] = {
  'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
}

default['mattermost']['log_file_directory'] = '/var/log/gitlab/mattermost'
default['mattermost']['service_use_ssl'] = false
default['mattermost']['service_address'] = "127.0.0.1"
default['mattermost']['service_port'] = "8065"
default['mattermost']['service_site_url'] = nil
default['mattermost']['service_allowed_untrusted_internal_connections'] = nil
default['mattermost']['service_enable_api_team_deletion'] = true
default['mattermost']['sql_driver_name'] = 'postgres'
default['mattermost']['sql_data_source'] = nil
default['mattermost']['gitlab'] = {}
default['mattermost']['file_directory'] = "/var/opt/gitlab/mattermost/data"
default['mattermost']['team_site_name'] = "GitLab Mattermost"
default['mattermost']['gitlab_enable'] = false
default['mattermost']['gitlab_secret'] = nil
default['mattermost']['gitlab_id'] = nil
default['mattermost']['gitlab_scope'] = nil
default['mattermost']['gitlab_auth_endpoint'] = nil
default['mattermost']['gitlab_token_endpoint'] = nil
default['mattermost']['gitlab_user_api_endpoint'] = nil
default['mattermost']['plugin_directory'] = "/var/opt/gitlab/mattermost/plugins"
default['mattermost']['plugin_client_directory'] = "/var/opt/gitlab/mattermost/client-plugins"
