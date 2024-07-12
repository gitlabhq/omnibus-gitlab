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
redis_exporter_static_etc_dir = node['monitoring']['redis_exporter']['env_directory']
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('redis-exporter')

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

directory redis_exporter_static_etc_dir do
  owner redis_user
  mode '0700'
  recursive true
end

env_dir redis_exporter_static_etc_dir do
  variables node['monitoring']['redis_exporter']['env']
  notifies :restart, "runit_service[redis-exporter]"
end

runtime_flags = PrometheusHelper.new(node).flags('redis_exporter')
redis_helper = RedisHelper::RedisExporter.new(node)
redis_url = redis_helper.formatted_redis_url

runit_service 'redis-exporter' do
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    flags: runtime_flags,
    env_dir: redis_exporter_static_etc_dir,
    redis_url: redis_url,
  }.merge(params))
  log_options logging_settings[:options]
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start redis-exporter" do
    retries 20
  end
end

consul_service node['monitoring']['redis_exporter']['consul_service_name'] do
  id 'redis-exporter'
  meta node['monitoring']['redis_exporter']['consul_service_meta']
  action Prometheus.service_discovery_action
  socket_address node['monitoring']['redis_exporter']['listen_address']
  reload_service false unless Services.enabled?('consul')
end
