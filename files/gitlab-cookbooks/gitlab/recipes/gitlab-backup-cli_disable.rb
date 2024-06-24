#
# Copyright:: Copyright (c) 2024 GitLab Inc.
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

install_dir = node['package']['install-dir']
gitlab_backup_cli_config_file = "#{install_dir}/etc/gitlab-backup-cli-config.yml"

template gitlab_backup_cli_config_file do
  owner 'root'
  group 'root'
  mode  '0644'
  source 'gitlab-backup-cli-config.yml.erb'
  sensitive true
  action :delete
end

account "GitLab Backup User" do
  username node['gitlab']['gitlab_backup_cli']['user']
  manage node['gitlab']['manage_accounts']['enable']
  action :remove
end

node['gitlab']['gitlab_backup_cli']['additional_groups'].each do |group_name|
  group group_name do
    append true
    excluded_members node['gitlab']['gitlab_backup_cli']['user']
    action :manage
  end
end
