#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2015 GitLab B.V.
# License:: Apache License, Version 2.0
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
gitlab = node['gitlab']

mattermost_user = gitlab['mattermost']['username']
mattermost_group = gitlab['mattermost']['group']
mattermost_home = gitlab['mattermost']['home']
mattermost_log_dir = gitlab['mattermost']['log_file_directory']
mattermost_storage_directory = gitlab['mattermost']['service_storage_directory']
postgresql_socket_dir = gitlab['postgresql']['unix_socket_directory']
pg_port = gitlab['postgresql']['port']
pg_user = gitlab['postgresql']['username']

###
# Create group and user that will be running mattermost
###
account "Mattermost user and group" do
  username mattermost_user
  ugid mattermost_group
  groupname mattermost_group
  shell '/bin/sh'
  home mattermost_home
  manage node['gitlab']['manage-accounts']['enable']
end

###
# Create required directories
###

[
  mattermost_home,
  mattermost_log_dir,
  mattermost_storage_directory
].compact.each do |dir|
  directory dir do
    owner mattermost_user
    recursive true
  end
end

###
# Create the database users, create the database we need, and grant them
# privileges.
###

pg_helper = PgHelper.new(node)
bin_dir = "/opt/gitlab/embedded/bin"

db_name = gitlab['mattermost']['database_name']
sql_user = gitlab['postgresql']['sql_mattermost_user']

execute "create #{sql_user} database user" do
  command "#{bin_dir}/psql --port #{pg_port} -h #{postgresql_socket_dir} -d template1 -c \"CREATE USER #{sql_user}\""
  user pg_user
  not_if { !pg_helper.is_running? || pg_helper.user_exists?(sql_user) }
end

execute "create #{db_name} database" do
  command "#{bin_dir}/createdb --port #{pg_port} -h #{postgresql_socket_dir} -O #{sql_user} #{db_name}"
  user pg_user
  not_if { !pg_helper.is_running? || pg_helper.database_exists?(db_name) }
  retries 30
end

###
# Populate mattermost configuration options
###
# Try connecting to GitLab only if it is enabled
database_ready = pg_helper.is_running? && pg_helper.database_exists?(gitlab['gitlab-rails']['db_database'])
gitlab_oauth  = if gitlab['mattermost']['oauth']['gitlab']
                  gitlab['mattermost']['oauth']['gitlab']
                else
                  if gitlab['gitlab-rails']['enable'] && database_ready
                     MattermostHelper.authorize_with_gitlab(Gitlab['external_url'])
                  else
                    {}
                  end
                end
oauth_attributes = gitlab['mattermost']['oauth'].to_hash.merge('gitlab' => gitlab_oauth)

template "#{mattermost_home}/config.json" do
  source "config.json.erb"
  owner mattermost_user
  variables gitlab['mattermost'].to_hash.merge(gitlab['postgresql']).to_hash.merge('oauth' => oauth_attributes)
  mode "0644"
  notifies :restart, "service[mattermost]"
end

###
# Mattermost control service
###

runit_service "mattermost" do
  options({
    :log_directory => mattermost_log_dir
  }.merge(params))
  log_options gitlab['logging'].to_hash.merge(gitlab['mattermost'].to_hash)
end
