#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
redis_user = account_helper.redis_user
redis_exporter_log_dir = node['monitoring']['redis-exporter']['log_directory']
redis_exporter_static_etc_dir = node['monitoring']['redis-exporter']['env_directory']

directory redis_exporter_log_dir do
  owner redis_user
  mode '0700'
  recursive true
end

directory redis_exporter_static_etc_dir do
  owner redis_user
  mode '0700'
  recursive true
end

env_dir redis_exporter_static_etc_dir do
  variables node['monitoring']['redis-exporter']['env']
  notifies :restart, "runit_service[redis-exporter]"
end

runtime_flags = PrometheusHelper.new(node).flags('redis-exporter')
runit_service 'redis-exporter' do
  options({
    log_directory: redis_exporter_log_dir,
    flags: runtime_flags,
    env_dir: redis_exporter_static_etc_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['registry'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start redis-exporter" do
    retries 20
  end
end

consul_service 'redis-exporter' do
  action Prometheus.service_discovery_action
  socket_address node['monitoring']['redis-exporter']['listen_address']
  reload_service false unless node['consul']['enable']
end
