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
redis_helper = RedisHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitlab-exporter')
gitlab_user = account_helper.gitlab_user
gitlab_exporter_dir = node['monitoring']['gitlab_exporter']['home']
env_directory = node['monitoring']['gitlab_exporter']['env_directory']

directory gitlab_exporter_dir do
  owner gitlab_user
  mode "0755"
  recursive true
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

env_dir env_directory do
  variables node['monitoring']['gitlab_exporter']['env']
  notifies :restart, "runit_service[gitlab-exporter]"
end

connection_string = "dbname=#{node['gitlab']['gitlab_rails']['db_database']} user=#{node['gitlab']['gitlab_rails']['db_username']}"

connection_string += if node['postgresql']['enabled']
                       " host=#{node['postgresql']['dir']}"
                     else
                       " host=#{node['gitlab']['gitlab_rails']['db_host']} port=#{node['gitlab']['gitlab_rails']['db_port']} password=#{node['gitlab']['gitlab_rails']['db_password']}"
                     end

redis_url = redis_helper.redis_url(support_sentinel_groupname: false)

template "#{gitlab_exporter_dir}/gitlab-exporter.yml" do
  source "gitlab-exporter.yml.erb"
  owner gitlab_user
  mode "0600"
  notifies :restart, "runit_service[gitlab-exporter]"
  variables(
    probe_sidekiq: node['monitoring']['gitlab_exporter']['probe_sidekiq'],
    probe_elasticsearch: node['monitoring']['gitlab_exporter']['probe_elasticsearch'],
    elasticsearch_url: node['monitoring']['gitlab_exporter']['elasticsearch_url'],
    elasticsearch_authorization: node['monitoring']['gitlab_exporter']['elasticsearch_authorization'],
    redis_url: redis_url,
    connection_string: connection_string,
    redis_enable_client: node['gitlab']['gitlab_rails']['redis_enable_client']
  )
  sensitive true
end

version_file 'Create version file for GitLab-Exporter' do
  version_file_path File.join(gitlab_exporter_dir, 'RUBY_VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/ruby --version'
  notifies :restart, "runit_service[gitlab-exporter]"
end

runit_service "gitlab-exporter" do
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
  }.merge(params))
  log_options logging_settings[:options]
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start gitlab-exporter" do
    retries 20
  end
end

consul_service node['monitoring']['gitlab_exporter']['consul_service_name'] do
  id 'gitlab-exporter'
  meta node['monitoring']['gitlab_exporter']['consul_service_meta']
  action Prometheus.service_discovery_action
  ip_address node['monitoring']['gitlab_exporter']['listen_address']
  port node['monitoring']['gitlab_exporter']['listen_port'].to_i
  reload_service false unless Services.enabled?('consul')
end
