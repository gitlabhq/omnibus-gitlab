#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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
omnibus_helper = OmnibusHelper.new(node)
redis_helper = RedisHelper.new(node)

working_dir = node['gitlab-kas']['dir']
log_directory = node['gitlab-kas']['log_directory']
env_directory = node['gitlab-kas']['env_directory']
gitlab_kas_static_etc_dir = '/opt/gitlab/etc/gitlab-kas'
gitlab_kas_config_file = File.join(working_dir, 'gitlab-kas-config.yml')
gitlab_kas_authentication_secret_file = File.join(working_dir, 'authentication_secret_file')
gitlab_kas_private_api_authentication_secret_file = File.join(working_dir, 'private_api_authentication_secret_file')
redis_host, redis_port, redis_password = redis_helper.redis_params
redis_sentinels = node['gitlab']['gitlab-rails']['redis_sentinels']
redis_sentinels_master_name = node['redis']['master_name']
gitlab_kas_redis_password_file = File.join(working_dir, 'redis_password_file')
redis_default_port = URI::Redis::DEFAULT_PORT
redis_network = redis_helper.redis_url.scheme == 'unix' ? 'unix' : 'tcp'
redis_ssl = node['gitlab']['gitlab-rails']['redis_ssl']
redis_address = if redis_network == 'tcp'
                  "#{redis_host}:#{redis_port || redis_default_port}"
                else
                  node['gitlab']['gitlab-rails']['redis_socket']
                end

[
  working_dir,
  log_directory,
  gitlab_kas_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
end

version_file 'Create version file for Gitlab KAS' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/gitlab-kas --version'
  notifies :restart, 'runit_service[gitlab-kas]'
end

file gitlab_kas_authentication_secret_file do
  content node['gitlab-kas']['api_secret_key']
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]'
end

file gitlab_kas_private_api_authentication_secret_file do
  content node['gitlab-kas']['private_api_secret_key']
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]'
end

file gitlab_kas_redis_password_file do
  content redis_password
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]'
  only_if { redis_password && !redis_password.empty? }
end

template gitlab_kas_config_file do
  source 'gitlab-kas-config.yml.erb'
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  variables(
    node['gitlab-kas'].to_hash.merge(
      authentication_secret_file: gitlab_kas_authentication_secret_file,
      private_api_authentication_secret_file: gitlab_kas_private_api_authentication_secret_file,
      redis_network: redis_network,
      redis_address: redis_address,
      redis_ssl: redis_ssl,
      redis_default_port: redis_default_port,
      redis_password_file: redis_password ? gitlab_kas_redis_password_file : nil,
      redis_sentinels_master_name: redis_sentinels_master_name,
      redis_sentinels: redis_sentinels
    )
  )
  notifies :restart, 'runit_service[gitlab-kas]'
end

env_dir env_directory do
  variables node['gitlab-kas']['env']
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

runit_service 'gitlab-kas' do
  options({
    log_directory: log_directory,
    env_directory: env_directory,
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    config_file: gitlab_kas_config_file,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab-kas'].to_hash)
end
