#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2016 GitLab Inc.
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
prometheus_user = account_helper.prometheus_user
node_exporter_log_dir = node['monitoring']['node-exporter']['log_directory']
textfile_dir = File.join(node['monitoring']['node-exporter']['home'], 'textfile_collector')
node_exporter_static_etc_dir = node['monitoring']['node-exporter']['env_directory']

# node-exporter runs under the prometheus user account. If prometheus is
# disabled, it's up to this recipe to create the account
include_recipe 'monitoring::user'

directory node_exporter_log_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory node_exporter_static_etc_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

env_dir node_exporter_static_etc_dir do
  variables node['monitoring']['node-exporter']['env']
  notifies :restart, "runit_service[node-exporter]"
end

directory textfile_dir do
  owner prometheus_user
  mode '0755'
  recursive true
end

runtime_flags = PrometheusHelper.new(node).kingpin_flags('node-exporter')
runit_service 'node-exporter' do
  options({
    log_directory: node_exporter_log_dir,
    flags: runtime_flags,
    env_dir: node_exporter_static_etc_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(
    node['monitoring']['node-exporter'].to_hash
  )
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start node-exporter" do
    retries 20
  end
end

consul_service 'node-exporter' do
  action Prometheus.service_discovery_action
  socket_address node['monitoring']['node-exporter']['listen_address']
  reload_service false unless node['consul']['enable']
end
