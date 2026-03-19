#
# Copyright:: Copyright (c) 2026 GitLab Inc.
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

# Recipe for managing registry backup credential files
# Creates environment files used by backup/restore operations

install_dir = node['package']['install-dir']
backup_env_dir = "#{install_dir}/etc/gitlab-backup/env"
backup_env_connection_file = File.join(backup_env_dir, 'env-connection')
backup_env_backup_user_file = File.join(backup_env_dir, 'env-backup_user')
backup_env_restore_user_file = File.join(backup_env_dir, 'env-restore_user')

directory backup_env_dir do
  owner 'root'
  group 'root'
  mode '0750'
  recursive true
end

# Create connection file for metadata registry DB
template backup_env_connection_file do
  source 'registry-env-db_connection.erb'
  owner 'root'
  group 'root'
  mode '0400'
  sensitive true
  variables(GitlabRails.registry_connection_variables)
end

backup_vars = GitlabRails.backup_user_variables
if backup_vars[:username].to_s.empty?
  file backup_env_backup_user_file do
    action :delete
  end
else
  template backup_env_backup_user_file do
    source 'registry-env-db_user.erb'
    owner 'root'
    group 'root'
    mode '0400'
    sensitive true
    variables(backup_vars)
  end
end

restore_vars = GitlabRails.restore_user_variables
if restore_vars[:username].to_s.empty?
  file backup_env_restore_user_file do
    action :delete
  end
else
  template backup_env_restore_user_file do
    source 'registry-env-db_user.erb'
    owner 'root'
    group 'root'
    mode '0400'
    sensitive true
    variables(restore_vars)
  end
end
