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
postgres_exporter_log_dir = node['gitlab']['postgres-exporter']['log_directory']
postgres_exporter_env_dir = node['gitlab']['postgres-exporter']['env_directory']
postgres_exporter_dir = node['gitlab']['postgres-exporter']['home']

node.default['gitlab']['postgres-exporter']['env']['DATA_SOURCE_NAME'] = "user=#{node['gitlab']['postgresql']['username']} " \
                                                                         "host=#{node['gitlab']['gitlab-rails']['db_host']} " \
                                                                         "database=postgres sslmode=allow"

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
  variables node['gitlab']['postgres-exporter']['env']
  notifies :restart, "service[postgres-exporter]"
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
  notifies :restart, 'service[postgres-exporter]'
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgres-exporter" do
    retries 20
  end
end
