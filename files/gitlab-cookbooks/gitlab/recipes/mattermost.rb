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

gitlab_home = node['gitlab']['user']['home']

mattermost_home = "#{gitlab_home}/mattermost"
mattermost_log_dir = "/var/log/gitlab/mattermost"
mattermost_user = node['mattermost']['username']
postgresql_socket_dir = node['gitlab']['postgresql']['unix_socket_directory']

group mattermost_user do
  system true
end

user mattermost_user do
  shell '/bin/sh'
  home mattermost_home
  gid mattermost_user
  system true
end

[ mattermost_home, mattermost_log_dir ].compact.each do |dir|

  directory dir do
    owner mattermost_user
    recursive true
  end
end

###
# Create the database, migrate it, and create the users we need, and grant them
# privileges.
###
pg_helper = PgHelper.new(node)
pg_port = node['gitlab']['postgresql']['port']
pg_user = node['gitlab']['postgresql']['username']
bin_dir = "/opt/gitlab/embedded/bin"

db_name = "mattermost_test"
sql_user = node['gitlab']['postgresql']['sql_mattermost_user']

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

template "#{mattermost_home}/config.json" do
  source "config.json.erb"
  owner mattermost_user
  mode "0644"
end
