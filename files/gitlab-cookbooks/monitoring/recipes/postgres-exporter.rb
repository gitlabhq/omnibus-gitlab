#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2016 Gitlab Inc.
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
postgresql_user = account_helper.postgresql_user
postgres_exporter_log_dir = node['monitoring']['postgres-exporter']['log_directory']
postgres_exporter_env_dir = node['monitoring']['postgres-exporter']['env_directory']
postgres_exporter_dir = node['monitoring']['postgres-exporter']['home']
postgres_exporter_sslmode = " sslmode=#{node['monitoring']['postgres-exporter']['sslmode']}" \
  unless node['monitoring']['postgres-exporter']['sslmode'].nil?
postgres_exporter_connection_string = if node['postgresql']['enable']
                                        "host=#{node['postgresql']['dir']} user=#{node['postgresql']['username']}"
                                      else
                                        "host=#{node['gitlab']['gitlab-rails']['db_host']} " \
                                        "port=#{node['gitlab']['gitlab-rails']['db_port']} " \
                                        "user=#{node['gitlab']['gitlab-rails']['db_username']} "\
                                        "password=#{node['gitlab']['gitlab-rails']['db_password']}"
                                      end
postgres_exporter_database = "#{node['gitlab']['gitlab-rails']['db_database']}#{postgres_exporter_sslmode}"

node.default['monitoring']['postgres-exporter']['env']['DATA_SOURCE_NAME'] = "#{postgres_exporter_connection_string} " \
                                                                             "database=#{postgres_exporter_database}"

include_recipe 'postgresql::user'

directory postgres_exporter_log_dir do
  owner postgresql_user
  mode '0700'
  recursive true
end

directory postgres_exporter_dir do
  owner postgresql_user
  mode '0700'
  recursive true
end

env_dir postgres_exporter_env_dir do
  variables node['monitoring']['postgres-exporter']['env']
  notifies :restart, "runit_service[postgres-exporter]"
end

runtime_flags = PrometheusHelper.new(node).kingpin_flags('postgres-exporter')
runit_service 'postgres-exporter' do
  options({
    log_directory: postgres_exporter_log_dir,
    flags: runtime_flags,
    env_dir: postgres_exporter_env_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['registry'].to_hash)
end

template File.join(postgres_exporter_dir, 'queries.yaml') do
  source 'postgres-queries.yaml'
  owner postgresql_user
  mode '0644'
  notifies :restart, 'runit_service[postgres-exporter]'
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgres-exporter" do
    retries 20
  end
end

consul_service 'postgres-exporter' do
  action Prometheus.service_discovery_action
  socket_address node['monitoring']['postgres-exporter']['listen_address']
  reload_service false unless node['consul']['enable']
end
