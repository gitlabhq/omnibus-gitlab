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
mattermost_user = node['gitlab']['mattermost']['username']
mattermost_group = node['gitlab']['mattermost']['group']
mattermost_uid = node['gitlab']['mattermost']['uid']
mattermost_gid = node['gitlab']['mattermost']['gid']
mattermost_home = node['gitlab']['mattermost']['home']
mattermost_log_dir = node['gitlab']['mattermost']['log_file_directory']
mattermost_storage_directory = node['gitlab']['mattermost']['file_directory']
postgresql_socket_dir = node['gitlab']['postgresql']['unix_socket_directory']
pg_port = node['gitlab']['postgresql']['port']
pg_user = node['gitlab']['postgresql']['username']
config_file_path = File.join(mattermost_home, "config.json")
mattermost_log_file = File.join(mattermost_log_dir, 'mattermost.log')

###
# Create group and user that will be running mattermost
###
account "Mattermost user and group" do
  username mattermost_user
  uid mattermost_uid
  ugid mattermost_group
  groupname mattermost_group
  gid mattermost_gid
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

# Fix an issue where GitLab 8.9 would create the log file as root on error
file mattermost_log_file do
  owner mattermost_user
  only_if { File.exist? mattermost_log_file }
end

###
# Create the database users, create the database we need, and grant them
# privileges.
###

pg_helper = PgHelper.new(node)
bin_dir = "/opt/gitlab/embedded/bin"

mysql_adapter = node['gitlab']['mattermost']['sql_driver_name'] == 'mysql' ? true:false
db_name = node['gitlab']['mattermost']['database_name']
sql_user = node['gitlab']['postgresql']['sql_mattermost_user']

execute "create #{sql_user} database user" do
  command "#{bin_dir}/psql --port #{pg_port} -h #{postgresql_socket_dir} -d template1 -c \"CREATE USER #{sql_user}\""
  user pg_user
  not_if { mysql_adapter || !pg_helper.is_running? || pg_helper.user_exists?(sql_user) }
end

execute "create #{db_name} database" do
  command "#{bin_dir}/createdb --port #{pg_port} -h #{postgresql_socket_dir} -O #{sql_user} #{db_name}"
  user pg_user
  not_if { mysql_adapter || !pg_helper.is_running? || pg_helper.database_exists?(db_name) }
  retries 30
end

###
# Populate mattermost configuration options
###
# Try connecting to GitLab only if it is enabled
database_ready = pg_helper.is_running? && pg_helper.database_exists?(node['gitlab']['gitlab-rails']['db_database'])

unless node['gitlab']['mattermost']['gitlab_enable']
  if node['gitlab']['gitlab-rails']['enable'] && database_ready
    MattermostHelper.authorize_with_gitlab(Gitlab['external_url'])
  end
end

node.consume_attributes(Gitlab.generate_hash)

template config_file_path do
  source "config.json.erb"
  owner mattermost_user
  variables node['gitlab']['mattermost'].to_hash.merge(node['gitlab']['postgresql']).to_hash
  mode "0644"
  notifies :restart, "service[mattermost]"
end

##################
# Upgrade from V2 to V3 workarounds
backup_done = node['gitlab']['mattermost']['db2_backup_created']
default_team_name_for_v2_upgrade = node['gitlab']['mattermost']['db2_team_name']
default_team_name_set = !default_team_name_for_v2_upgrade.nil?
log_file = File.join(mattermost_log_dir, "mattermost.log")
mattermost_helper = MattermostHelper.new(node, mattermost_user, mattermost_home)

# If mattermost version returns exit status different than 0, database
# migration most likely is not possible
# stop the running service, something went wrong
execute "/opt/gitlab/bin/gitlab-ctl stop mattermost" do
  retries 20
  only_if { mattermost_helper.version.nil? }
end

if backup_done && default_team_name_set
  execute "/opt/gitlab/bin/gitlab-ctl start mattermost" do
    retries 2
    only_if { mattermost_helper.version.nil? && MattermostHelper.upgrade_db_30(config_file_path, mattermost_user, default_team_name_for_v2_upgrade) == 0 }
  end
end

bash "Show the message of the failed upgrade." do
  code <<-EOS
    echo "!!!!Automatic database upgrade failed.!!!\n
    If you are upgrading from Mattermost v2 to v3
    make sure that you have backed up your database
    and then in /etc/gitlab/gitlab.rb set:

    mattermost['db2_backup_created'] = true
    mattermost['db2_team_name'] = \"TEAMNAME\"\n

    where "TEAMNAME" is the name of the default team.
    Run gitlab-ctl reconfigure again.
    See: \n
    http://docs.gitlab.com/omnibus/gitlab-mattermost/#upgrading-gitlab-mattermost-from-versions-prior-to-8.9 \n
    for more information.\n
    " >> #{log_file}
  EOS
  user mattermost_user
  only_if { mattermost_helper.version.nil? && !(backup_done && default_team_name_set) }
end

###############

###
# Mattermost control service
###

runit_service "mattermost" do
  options({
    :log_directory => mattermost_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['mattermost'].to_hash)
end
