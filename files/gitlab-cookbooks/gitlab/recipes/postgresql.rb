#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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
account_helper = AccountHelper.new(node)

postgresql_dir = node['gitlab']['postgresql']['dir']
postgresql_data_dir = node['gitlab']['postgresql']['data_dir']
postgresql_data_dir_symlink = File.join(postgresql_dir, "data")
postgresql_log_dir = node['gitlab']['postgresql']['log_directory']
postgresql_socket_dir = node['gitlab']['postgresql']['unix_socket_directory']
postgresql_user = account_helper.postgresgl_user

pg_helper = PgHelper.new(node)

account "Postgresql user and group" do
  username postgresql_user
  uid node['gitlab']['postgresql']['uid']
  ugid postgresql_user
  groupname postgresql_user
  gid node['gitlab']['postgresql']['gid']
  shell node['gitlab']['postgresql']['shell']
  home node['gitlab']['postgresql']['home']
  manage node['gitlab']['manage-accounts']['enable']
end

directory postgresql_dir do
  owner postgresql_user
  mode "0755"
  recursive true
end

[
  postgresql_data_dir,
  postgresql_log_dir
].each do |dir|
  directory dir do
    owner postgresql_user
    mode "0700"
    recursive true
  end
end

link postgresql_data_dir_symlink do
  to postgresql_data_dir
  not_if { postgresql_data_dir == postgresql_data_dir_symlink }
end

file File.join(node['gitlab']['postgresql']['home'], ".profile") do
  owner postgresql_user
  mode "0600"
  content <<-EOH
PATH=#{node['gitlab']['postgresql']['user_path']}
EOH
end

sysctl "kernel.shmmax" do
  value node['gitlab']['postgresql']['shmmax']
end

sysctl "kernel.shmall" do
  value node['gitlab']['postgresql']['shmall']
end

sem = "#{node['gitlab']['postgresql']['semmsl']} "
sem += "#{node['gitlab']['postgresql']['semmns']} "
sem += "#{node['gitlab']['postgresql']['semopm']} "
sem += "#{node['gitlab']['postgresql']['semmni']}"
sysctl "kernel.sem" do
  value sem
end

execute "/opt/gitlab/embedded/bin/initdb -D #{postgresql_data_dir} -E UTF8" do
  user postgresql_user
  not_if { File.exists?(File.join(postgresql_data_dir, "PG_VERSION")) }
end

postgresql_config = File.join(postgresql_data_dir, "postgresql.conf")

node.default['gitlab']['postgresql']['version'] = pg_helper.version

template postgresql_config do
  source "postgresql.conf.erb"
  owner postgresql_user
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]', :immediately if OmnibusHelper.should_notify?("postgresql")
end

pg_hba_config = File.join(postgresql_data_dir, "pg_hba.conf")

template pg_hba_config do
  source "pg_hba.conf.erb"
  owner postgresql_user
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]', :immediately if OmnibusHelper.should_notify?("postgresql")
end

template File.join(postgresql_data_dir, "pg_ident.conf") do
  owner postgresql_user
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]' if OmnibusHelper.should_notify?("postgresql")
end

should_notify = OmnibusHelper.should_notify?("postgresql")

runit_service "postgresql" do
  down node['gitlab']['postgresql']['ha']
  control(['t'])
  options({
    :log_directory => postgresql_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['postgresql'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgresql" do
    retries 20
  end
end

###
# Create the database, migrate it, and create the users we need, and grant them
# privileges.
###

# This template is needed to make the gitlab-psql script and PgHelper work
template "/opt/gitlab/etc/gitlab-psql-rc" do
  owner 'root'
  group 'root'
end

pg_port = node['gitlab']['postgresql']['port']
database_name = node['gitlab']['gitlab-rails']['db_database']
gitlab_sql_user = node['gitlab']['postgresql']['sql_user']
sql_replication_user = node['gitlab']['postgresql']['sql_replication_user']


if node['gitlab']['gitlab-rails']['enable']
  execute "create #{gitlab_sql_user} database user" do
    command "/opt/gitlab/bin/gitlab-psql -d template1 -c \"CREATE USER #{gitlab_sql_user}\""
    user postgresql_user
    # Added retries to give the service time to start on slower systems
    retries 20
    not_if { !pg_helper.is_running? || pg_helper.user_exists?(gitlab_sql_user) }
  end

  execute "create #{database_name} database" do
    command "/opt/gitlab/embedded/bin/createdb --port #{pg_port} -h #{postgresql_socket_dir} -O #{gitlab_sql_user} #{database_name}"
    user postgresql_user
    retries 30
    not_if { !pg_helper.is_running? || pg_helper.database_exists?(database_name) }
  end

  execute "create #{sql_replication_user} replication user" do
    command "/opt/gitlab/bin/gitlab-psql -d template1 -c \"CREATE USER #{sql_replication_user} REPLICATION\""
    user postgresql_user
    # Added retries to give the service time to start on slower systems
    retries 20
    not_if { !pg_helper.is_running? || pg_helper.user_exists?(sql_replication_user) }
  end
end

execute "enable pg_trgm extension" do
  command "/opt/gitlab/bin/gitlab-psql -d #{database_name} -c \"CREATE EXTENSION IF NOT EXISTS pg_trgm;\""
  user postgresql_user
  retries 20
  action :nothing
  not_if { !pg_helper.is_running? || pg_helper.is_slave? }
end
