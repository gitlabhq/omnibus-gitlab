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
omnibus_helper = OmnibusHelper.new(node)
pgb_helper = PgbouncerHelper.new(node)

node.default['gitlab']['pgbouncer']['unix_socket_dir'] ||= node['gitlab']['pgbouncer']['data_directory']

include_recipe 'postgresql::user'

# If consul is enabled, it needs to run before pgbouncer
include_recipe 'consul::enable' if node['consul']['enable']

[
  node['gitlab']['pgbouncer']['log_directory'],
  node['gitlab']['pgbouncer']['data_directory']
].each do |dir|
  directory dir do
    owner account_helper.postgresql_user
    mode '0700'
    recursive true
  end
end

template "#{node['gitlab']['pgbouncer']['data_directory']}/pg_auth" do
  source "pg_auth.erb"
  helper(:pgb_helper) { pgb_helper }
end

runit_service 'pgbouncer' do
  options(
    username: node['gitlab']['postgresql']['username'],
    data_directory: node['gitlab']['pgbouncer']['data_directory'],
    log_directory: node['gitlab']['pgbouncer']['log_directory']
  )
end

template "#{node['gitlab']['pgbouncer']['data_directory']}/pgbouncer.ini" do
  source "#{File.basename(name)}.erb"
  variables lazy { node['gitlab']['pgbouncer'].to_hash }
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
  notifies :run, 'execute[reload pgbouncer]', :immediately
end

file 'databases.json' do
  path lazy { node['gitlab']['pgbouncer']['databases_json'] }
  user lazy { node['gitlab']['pgbouncer']['databases_ini_user'] }
  group account_helper.postgresql_group
  mode '0600'
  content node['gitlab']['pgbouncer']['databases'].to_json
  notifies :run, 'execute[generate databases.ini]', :immediately
end

execute 'generate databases.ini' do
  command lazy {
    <<~EOF
    /opt/gitlab/bin/gitlab-ctl pgb-notify \
     --databases-json #{node['gitlab']['pgbouncer']['databases_json']} \
     --databases-ini #{node['gitlab']['pgbouncer']['databases_ini']} \
     --hostuser #{node['gitlab']['pgbouncer']['databases_ini_user']} \
     --hostgroup #{node['gitlab']['postgresql']['username']} \
     --pg-host #{node['gitlab']['pgbouncer']['listen_addr']} \
     --pg-port #{node['gitlab']['pgbouncer']['listen_port']} \
     --user #{node['gitlab']['postgresql']['pgbouncer_user']}
    EOF
  }
  action :nothing
end

execute 'reload pgbouncer' do
  command '/opt/gitlab/bin/gitlab-ctl hup pgbouncer'
  action :nothing
  only_if { omnibus_helper.service_up?('pgbouncer') }
end

execute 'start pgbouncer' do
  command '/opt//gitlab/bin/gitlab-ctl start pgbouncer'
  action :nothing
  not_if { omnibus_helper.service_up?('pgbouncer') }
end
