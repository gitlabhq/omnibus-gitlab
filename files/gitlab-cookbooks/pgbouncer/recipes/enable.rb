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

account_helper = AccountHelper.new(node)
pgb_helper = PgbouncerHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('pgbouncer')
pgbouncer_static_etc_dir = node['pgbouncer']['env_directory']

node.default['pgbouncer']['unix_socket_dir'] ||= node['pgbouncer']['data_directory']

include_recipe 'postgresql::user'

[
  node['pgbouncer']['data_directory'],
  pgbouncer_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.postgresql_user
    mode '0700'
    recursive true
  end
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

env_dir pgbouncer_static_etc_dir do
  variables node['pgbouncer']['env']
  notifies :restart, "runit_service[pgbouncer]"
end

template "#{node['pgbouncer']['data_directory']}/pg_auth" do
  source "pg_auth.erb"
  variables(node['pgbouncer'])
  helper(:pgb_helper) { pgb_helper }
end

runit_service 'pgbouncer' do
  options(
    username: node['postgresql']['username'],
    groupname: node['postgresql']['group'],
    data_directory: node['pgbouncer']['data_directory'],
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    env_dir: pgbouncer_static_etc_dir
  )
end

template "#{node['pgbouncer']['data_directory']}/pgbouncer.ini" do
  source "#{File.basename(name)}.erb"
  variables lazy { node['pgbouncer'].to_hash }
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
  notifies :run, 'execute[reload pgbouncer]', :immediately
end

file 'databases.json' do
  path lazy { node['pgbouncer']['databases_json'] }
  user lazy { node['pgbouncer']['databases_ini_user'] }
  group account_helper.postgresql_group
  mode '0600'
  content node['pgbouncer']['databases'].to_json
  notifies :run, 'execute[generate databases.ini]', :immediately
end

execute 'generate databases.ini' do
  command lazy {
    <<~EOF
    /opt/gitlab/bin/gitlab-ctl pgb-notify \
     --databases-json #{node['pgbouncer']['databases_json']} \
     --databases-ini #{node['pgbouncer']['databases_ini']} \
     --hostuser #{node['pgbouncer']['databases_ini_user']} \
     --hostgroup #{account_helper.postgresql_group} \
     --pg-host #{node['pgbouncer']['listen_addr']} \
     --pg-port #{node['pgbouncer']['listen_port']} \
     --user #{node['postgresql']['pgbouncer_user']}
    EOF
  }
  action :nothing
  not_if do
    node['consul']['watchers'].include?('postgresql') &&
      File.exist?(node['pgbouncer']['databases_ini'])
  end
  retries 3
end

execute 'reload pgbouncer' do
  command '/opt/gitlab/bin/gitlab-ctl hup pgbouncer'
  action :nothing
  only_if { pgb_helper.running? }
end

execute 'start pgbouncer' do
  command '/opt//gitlab/bin/gitlab-ctl start pgbouncer'
  action :nothing
  not_if { pgb_helper.running? }
end
