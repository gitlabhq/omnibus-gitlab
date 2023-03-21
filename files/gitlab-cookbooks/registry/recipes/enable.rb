#
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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('registry')
registry_uid = node['registry']['uid']
registry_gid = node['registry']['gid']

working_dir = node['registry']['dir']
log_format = node['registry']['log_formatter']
env_directory = node['registry']['env_directory']

directory "create #{working_dir}" do
  path working_dir
  recursive true
end

account "Docker registry user and group" do
  username account_helper.registry_user
  uid registry_uid
  ugid account_helper.registry_group
  groupname account_helper.registry_group
  gid registry_gid
  shell '/bin/sh'
  home working_dir
  manage node['gitlab']['manage_accounts']['enable']
end

directory "create #{working_dir} and set the owner" do
  path working_dir
  owner account_helper.registry_user
  mode '0700'
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
  variables node['registry']['env']
  notifies :restart, "runit_service[registry]"
end

directory node['gitlab']['gitlab_rails']['registry_path'] do
  owner account_helper.registry_user
  group account_helper.gitlab_group
  mode '0770'
  recursive true
  only_if { node['gitlab']['manage_storage_directories']['enable'] }
end

cert_file_path = File.join(working_dir, "gitlab-registry.crt")
node.default['registry']['rootcertbundle'] = cert_file_path
file cert_file_path do
  content node['registry']['internal_certificate']
  owner account_helper.registry_user
  group account_helper.registry_group
  sensitive true
end

template "#{working_dir}/config.yml" do
  source "registry-config.yml.erb"
  owner account_helper.registry_user
  variables node['registry'].to_hash.merge(node['gitlab']['gitlab_rails'].to_hash)
  mode "0644"
  notifies :restart, "runit_service[registry]"
end

runit_service 'registry' do
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    log_format: log_format
  }.merge(params))
  log_options logging_settings[:options]
end

version_file 'Create version file for Registry' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/registry --version'
  notifies :restart, "runit_service[registry]"
end
