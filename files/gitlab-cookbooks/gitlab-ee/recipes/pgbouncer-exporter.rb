#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2018 Gitlab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
account_helper = AccountHelper.new(node)
pgb_helper = PgbouncerHelper.new(node)
postgresql_user = account_helper.postgresql_user
pgbouncer_exporter_log_dir = node['gitlab']['pgbouncer-exporter']['log_directory']
pgbouncer_exporter_listen_address = node['gitlab']['pgbouncer-exporter']['listen_address']
pgbouncer_connection_string = pgb_helper.pgbouncer_admin_config
pgbouncer_exporter_static_etc_dir = node['gitlab']['pgbouncer-exporter']['env_directory']

include_recipe 'postgresql::user'

directory pgbouncer_exporter_log_dir do
  owner postgresql_user
  mode '0700'
  recursive true
end

directory pgbouncer_exporter_static_etc_dir do
  owner postgresql_user
  mode '0700'
  recursive true
end

env_dir pgbouncer_exporter_static_etc_dir do
  variables node['gitlab']['pgbouncer-exporter']['env']
  notifies :restart, "runit_service[pgbouncer-exporter]"
end

runit_service 'pgbouncer-exporter' do
  options(
    username: node['postgresql']['username'],
    connection_string: pgbouncer_connection_string,
    listen_address: pgbouncer_exporter_listen_address,
    log_directory: pgbouncer_exporter_log_dir,
    env_dir: pgbouncer_exporter_static_etc_dir
  )
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['pgbouncer-exporter'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start pgbouncer-exporter" do
    retries 20
  end
end
