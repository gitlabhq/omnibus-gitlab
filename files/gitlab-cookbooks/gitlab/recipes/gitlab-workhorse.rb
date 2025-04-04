#
# Copyright:: Copyright (c) 2015 GitLab Inc.
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
redis_helper = RedisHelper::GitlabWorkhorse.new(node)
workhorse_helper = GitlabWorkhorseHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitlab-workhorse')

working_dir = node['gitlab']['gitlab_workhorse']['dir']
gitlab_workhorse_static_etc_dir = "/opt/gitlab/etc/gitlab-workhorse"
workhorse_env_dir = node['gitlab']['gitlab_workhorse']['env_directory']
gitlab_workhorse_socket_dir = node['gitlab']['gitlab_workhorse']['sockets_directory']

directory working_dir do
  owner account_helper.gitlab_user
  group account_helper.web_server_group
  mode '0750'
  recursive true
end

if workhorse_helper.unix_socket? && !gitlab_workhorse_socket_dir.nil?
  directory gitlab_workhorse_socket_dir do
    owner account_helper.gitlab_user
    group account_helper.web_server_group
    mode '0750'
    notifies :restart, "runit_service[gitlab-workhorse]"
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

directory gitlab_workhorse_static_etc_dir do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

env_dir workhorse_env_dir do
  variables node['gitlab']['gitlab_workhorse']['env']
  notifies :restart, "runit_service[gitlab-workhorse]"
end

runit_service 'gitlab-workhorse' do
  start_down node['gitlab']['gitlab_workhorse']['ha']
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
  }.merge(params))
  log_options logging_settings[:options]
end

consul_service node['gitlab']['gitlab_workhorse']['consul_service_name'] do
  id 'workhorse'
  action Prometheus.service_discovery_action
  socket_address node['gitlab']['gitlab_workhorse']['prometheus_listen_addr']
  reload_service false unless Services.enabled?('consul')
end

version_file 'Create version file for Workhorse' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/gitlab-workhorse --version'
  notifies :restart, "runit_service[gitlab-workhorse]"
end

alt_document_root = node['gitlab']['gitlab_workhorse']['alt_document_root']
shutdown_timeout = node['gitlab']['gitlab_workhorse']['shutdown_timeout']
workhorse_keywatcher = node['gitlab']['gitlab_workhorse']['workhorse_keywatcher']
redis_params = redis_helper.redis_params
config_file_path = File.join(working_dir, "config.toml")
image_scaler_max_procs = node['gitlab']['gitlab_workhorse']['image_scaler_max_procs']
image_scaler_max_filesize = node['gitlab']['gitlab_workhorse']['image_scaler_max_filesize']
trusted_cidrs_for_propagation = node['gitlab']['gitlab_workhorse']['trusted_cidrs_for_propagation']
trusted_cidrs_for_x_forwarded_for = node['gitlab']['gitlab_workhorse']['trusted_cidrs_for_x_forwarded_for']
extra_config_command = node['gitlab']['gitlab_workhorse']['extra_config_command']
metadata_zip_reader_limit_bytes = node['gitlab']['gitlab_workhorse']['metadata_zip_reader_limit_bytes']

template config_file_path do
  source "workhorse-config.toml.erb"
  owner "root"
  group account_helper.gitlab_group
  mode "0640"
  variables(
    alt_document_root: alt_document_root,
    workhorse_keywatcher: workhorse_keywatcher,
    redis_url: redis_params[:url],
    password: redis_params[:password],
    sentinels: redis_params[:sentinels],
    sentinel_master: redis_params[:sentinelMaster],
    sentinel_password: redis_params[:sentinelPassword],
    shutdown_timeout: shutdown_timeout,
    image_scaler_max_procs: image_scaler_max_procs,
    image_scaler_max_filesize: image_scaler_max_filesize,
    trusted_cidrs_for_propagation: trusted_cidrs_for_propagation,
    trusted_cidrs_for_x_forwarded_for: trusted_cidrs_for_x_forwarded_for,
    object_store_toml: workhorse_helper.object_store_toml,
    extra_config_command: extra_config_command,
    metadata_zip_reader_limit_bytes: metadata_zip_reader_limit_bytes
  )
  notifies :restart, "runit_service[gitlab-workhorse]"
  notifies :run, 'bash[Set proper security context on ssh files for selinux]', :delayed if SELinuxHelper.enabled?
  sensitive true
end
