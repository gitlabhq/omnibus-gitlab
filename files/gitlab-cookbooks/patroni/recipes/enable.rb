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

# Re-define default values to recover any custom configuration provided by the user
node.default['patroni']['replication_user'] = node['postgresql']['sql_replication_user']

patroni_config_file = "#{node['patroni']['dir']}/patroni.yaml"
dcs_config_file = "#{node['patroni']['dir']}/dcs.yaml"

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
      postgresql_defaults: node['postgresql'].to_hash
    )
  )
  notifies :reload, 'runit_service[patroni]', :delayed if omnibus_helper.should_notify?(patroni_helper.service_name)
end

file dcs_config_file do
  content YAML.dump(patroni_helper.dynamic_settings)
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
  notifies :run, 'execute[update dynamic configuration settings]'
end

runit_service 'patroni' do
  supervisor_owner account_helper.postgresql_user
  supervisor_group account_helper.postgresql_group
  restart_on_update false
  options({
    user: account_helper.postgresql_user,
    groupname: account_helper.postgresql_group,
    log_directory: node['patroni']['log_directory'],
    patroni_config_file: patroni_config_file
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['patroni'].to_hash)
end

ruby_block 'wait for node bootstrap to complete' do
  block do
    Timeout.timeout(30) do
      sleep 2 until patroni_helper.node_status == 'running'
    end
  end
  action :nothing
end

execute 'update dynamic configuration settings' do
  command "#{patroni_helper.ctl_command} -c #{patroni_config_file} edit-config --force --replace #{dcs_config_file}"
  only_if { patroni_helper.node_status == 'running' }
  action :nothing
  notifies :run, 'ruby_block[wait for node bootstrap to complete]', :before
end

ruby_block 'wait for postgresql to start' do
  block do
    Timeout.timeout(30) do
      sleep 2 until pg_helper.ready?
    end
  end
end

execute 'reload postgresql' do
  command "#{patroni_helper.ctl_command} -c #{patroni_config_file} reload --force #{node['patroni']['scope']} #{node['patroni']['name']}"
  only_if { patroni_helper.node_status == 'running' }
  action :nothing
end

Dir["#{node['patroni']['data_dir']}/*"].each do |src|
  file "#{node['postgresql']['data_dir']}/#{File.basename(src)}" do
    owner account_helper.postgresql_user
    group account_helper.postgresql_group
    mode format('%o', File.new(src).stat.mode)[-5..-1]
    content lazy { File.open(src).read }
    sensitive !!(File.extname(src) =~ /\.(key|crt)/)
    only_if { patroni_helper.bootstrapped? }
    notifies :run, 'execute[reload postgresql]', :delayed
  end
end

database_objects 'patroni' do
  pg_helper pg_helper
  account_helper account_helper
  not_if { pg_helper.replica? }
end

execute 'signal to restart postgresql' do
  command "#{patroni_helper.ctl_command} -c #{patroni_config_file} restart --force #{node['patroni']['scope']} #{node['patroni']['name']}"
  not_if { patroni_helper.repmgr_data_present? }
  only_if { omnibus_helper.service_dir_enabled?('postgresql') && patroni_helper.node_status == 'running' }
  notifies :run, 'ruby_block[wait for node bootstrap to complete]', :before
end

include_recipe 'postgresql::disable'
