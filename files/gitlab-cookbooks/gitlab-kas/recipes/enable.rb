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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitlab-kas')

working_dir = node['gitlab_kas']['dir']
env_directory = node['gitlab_kas']['env_directory']
gitlab_kas_static_etc_dir = '/opt/gitlab/etc/gitlab-kas'
gitlab_kas_config_file = File.join(working_dir, 'gitlab-kas-config.yml')
gitlab_kas_authentication_secret_file = File.join(working_dir, 'authentication_secret_file')
gitlab_kas_private_api_authentication_secret_file = File.join(working_dir, 'private_api_authentication_secret_file')
redis_host, redis_port, redis_password = redis_helper.kas_params
redis_password_present = redis_password && !redis_password.empty?
redis_sentinels = node['gitlab_kas']['redis_sentinels']
redis_sentinels_master_name = node['gitlab_kas']['redis_sentinels_master_name']
redis_sentinels_password = node['gitlab_kas']['redis_sentinels_password']
redis_sentinels_password_present = redis_sentinels_password && !redis_sentinels_password.empty?

gitlab_kas_redis_password_file = File.join(working_dir, 'redis_password_file')
gitlab_kas_redis_sentinels_password_file = File.join(working_dir, 'redis_sentinels_password_file')
redis_default_port = URI::Redis::DEFAULT_PORT
redis_network = redis_helper.redis_url.scheme == 'unix' ? 'unix' : 'tcp'
redis_ssl = node['gitlab_kas']['redis_ssl']
redis_address = if redis_network == 'tcp'
                  "#{redis_host}:#{redis_port || redis_default_port}"
                else
                  node['gitlab_kas']['redis_socket']
                end
redis_tls_ca_cert_file = node['gitlab_kas']['redis_tls_ca_cert_file']
redis_tls_client_cert_file = node['gitlab_kas']['redis_tls_client_cert_file']
redis_tls_client_key_file = node['gitlab_kas']['redis_tls_client_key_file']

[
  working_dir,
  gitlab_kas_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
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

version_file 'Create version file for Gitlab KAS' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/gitlab-kas --version'
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

file gitlab_kas_authentication_secret_file do
  content node['gitlab_kas']['api_secret_key']
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

file gitlab_kas_private_api_authentication_secret_file do
  content node['gitlab_kas']['private_api_secret_key']
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

file gitlab_kas_redis_password_file do
  content redis_password
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
  only_if { redis_password_present }
  sensitive true
end

file gitlab_kas_redis_sentinels_password_file do
  content redis_sentinels_password
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
  only_if { redis_sentinels_password_present }
  sensitive true
end

template gitlab_kas_config_file do
  source 'gitlab-kas-config.yml.erb'
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  variables(
    node['gitlab_kas'].to_hash.merge(
      authentication_secret_file: gitlab_kas_authentication_secret_file,
      private_api_authentication_secret_file: gitlab_kas_private_api_authentication_secret_file,
      redis_network: redis_network,
      redis_address: redis_address,
      redis_ssl: redis_ssl,
      redis_tls_ca_cert_file: redis_tls_ca_cert_file,
      redis_tls_client_cert_file: redis_tls_client_cert_file,
      redis_tls_client_key_file: redis_tls_client_key_file,
      redis_default_port: redis_default_port,
      redis_password_file: redis_password_present ? gitlab_kas_redis_password_file : nil,
      redis_sentinels_master_name: redis_sentinels_master_name,
      redis_sentinels: redis_sentinels,
      redis_sentinels_password_file: redis_sentinels_password_present ? gitlab_kas_redis_sentinels_password_file : nil
    )
  )
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

env_dir env_directory do
  variables node['gitlab_kas']['env']
  notifies :restart, 'runit_service[gitlab-kas]' if omnibus_helper.should_notify?('gitlab-kas')
end

runit_service 'gitlab-kas' do
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    env_directory: env_directory,
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    config_file: gitlab_kas_config_file,
  }.merge(params))
  log_options logging_settings[:options]
  sensitive true
end
