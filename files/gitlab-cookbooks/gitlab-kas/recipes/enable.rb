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

working_dir = node['gitlab-kas']['dir']
log_directory = node['gitlab-kas']['log_directory']
env_directory = node['gitlab-kas']['env_directory']
gitlab_kas_static_etc_dir = '/opt/gitlab/etc/gitlab-kas'
gitlab_kas_config_file = File.join(working_dir, 'gitlab-kas-config.yml')
gitlab_kas_authentication_secret_file = File.join(working_dir, 'authentication_secret_file')

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

template gitlab_kas_config_file do
  source 'gitlab-kas-config.yml.erb'
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  variables(
    node['gitlab-kas'].to_hash.merge(
      authentication_secret_file: gitlab_kas_authentication_secret_file
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
