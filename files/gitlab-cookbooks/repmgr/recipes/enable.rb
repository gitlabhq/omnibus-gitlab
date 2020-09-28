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
#
account_helper = AccountHelper.new(node)
repmgr_helper = RepmgrHelper.new(node)
replication_user = node['repmgr']['username']
repmgr_conf = "#{node['postgresql']['dir']}/repmgr.conf"

pg_helper = PgHelper.new(node)

log_directory = node['repmgr']['log_directory']

node.default['postgresql']['custom_pg_hba_entries']['repmgr'] = repmgr_helper.pg_hba_entries

node_number = node['repmgr']['node_number'] || repmgr_helper.generate_node_number
template repmgr_conf do
  source 'repmgr.conf.erb'
  owner account_helper.postgresql_user
  variables(
    node['repmgr'].to_hash.merge(
      node_name: node['repmgr']['node_name'] || node['fqdn'],
      host: node['repmgr']['host'] || node['fqdn'],
      node_number: node_number
    )
  )
end

postgresql_user replication_user do
  options %w(SUPERUSER)
  not_if { pg_helper.is_standby? }
end

postgresql_database node['repmgr']['database'] do
  owner replication_user
  notifies :run, "execute[register repmgr master node]", :immediately if node['repmgr']['master_on_initialization']
end

execute 'register repmgr master node' do
  command "/opt/gitlab/embedded/bin/repmgr -f #{repmgr_conf} master register"
  user account_helper.postgresql_user
  action :nothing
end

directory log_directory do
  owner account_helper.postgresql_user
  mode '0700'
end

if node['repmgrd']['enable']
  include_recipe 'repmgr::repmgrd'
else
  include_recipe 'repmgr::repmgrd_disable'
end
