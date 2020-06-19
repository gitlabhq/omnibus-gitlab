#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

patroni_config_file = "#{node['patroni']['dir']}/patroni.yaml"
dcs_config_file = "#{node['patroni']['dir']}/dcs.yaml"
post_bootstrap = "#{node['patroni']['dir']}/post-bootstrap"

account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
pg_helper = PgHelper.new(node)
patroni_helper = PatroniHelper.new(node)

[
  node['patroni']['dir'],
  node['patroni']['data_dir'],
  node['patroni']['log_directory']
].each do |dir|
  directory dir do
    recursive true
    owner account_helper.postgresql_user
    group account_helper.postgresql_group
    mode '0700'
  end
end

template patroni_config_file do
  source 'patroni.yaml.erb'
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
  sensitive true
  helper(:pg_helper) { pg_helper }
  helper(:patroni_helper) { patroni_helper }
  helper(:account_helper) { account_helper }
  variables(
    node['patroni'].to_hash.merge(
      postgresql_defaults: node['postgresql'].to_hash,
      post_bootstrap: post_bootstrap
    )
  )
  notifies :reload, 'runit_service[patroni]', :delayed if omnibus_helper.should_notify?(patroni_helper.service_name)
end

default_auth_query = node.default['gitlab']['pgbouncer']['auth_query']
auth_query = node['gitlab']['pgbouncer']['auth_query']

template post_bootstrap do
  source 'post-bootstrap.erb'
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0700'
  sensitive true
  helper(:pg_helper) { pg_helper }
  variables(
    node['postgresql'].to_hash.merge(
      database_name: node['gitlab']['gitlab-rails']['db_database'],
      add_auth_function: default_auth_query.eql?(auth_query)
    )
  )
end

file dcs_config_file do
  content YAML.dump(patroni_helper.dynamic_settings)
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
end

runit_service 'patroni' do
  supervisor_owner account_helper.postgresql_user
  supervisor_group account_helper.postgresql_group
  restart_on_update false
  control(['t'])
  options({
    user: account_helper.postgresql_user,
    groupname: account_helper.postgresql_group,
    log_directory: node['patroni']['log_directory'],
    patroni_config_file: patroni_config_file
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['patroni'].to_hash)
end

ruby_block 'wait for node bootsrap to complete' do
  block do
    Timeout.timeout(30) do
      sleep 1 until patroni_helper.node_status == 'running'
    end
  end
  action :run
end

execute 'update dynamic configuration settings' do
  command "#{patroni_helper.ctl_command} -c #{patroni_config_file} edit-config --force --replace #{dcs_config_file}"
  only_if { patroni_helper.node_status == 'running' }
end

gitlab_sql_user = node['postgresql']['sql_user']
gitlab_sql_user_password = node['postgresql']['sql_user_password']
sql_replication_user = node['postgresql']['sql_replication_user']
sql_replication_password = node['postgresql']['sql_replication_password']

postgresql_user gitlab_sql_user do
  password "md5#{gitlab_sql_user_password}" unless gitlab_sql_user_password.nil?
  action :create
  retries 20
  ignore_failure true
  not_if { pg_helper.is_replica? }
end

postgresql_user sql_replication_user do
  password "md5#{sql_replication_password}" unless sql_replication_password.nil?
  options %w(replication)
  action :create
  retries 20
  ignore_failure true
  not_if { pg_helper.is_replica? }
end

return unless omnibus_helper.service_dir_enabled?('postgresql')

execute 'signal to restart postgresql' do
  command "#{patroni_helper.ctl_command} -c #{patroni_config_file} restart --force #{node['patroni']['scope']} #{node['patroni']['name']}"
  not_if { patroni_helper.repmgr_active? }
  only_if { patroni_helper.node_status == 'running' }
end

include_recipe 'postgresql::disable'
