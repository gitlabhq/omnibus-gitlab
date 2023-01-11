#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

gitlab_username = account_helper.gitlab_user
gitlab_group = account_helper.gitlab_group
gitlab_home = node['gitlab']['user']['home']

directory gitlab_home do
  recursive true
end

account "GitLab user and group" do
  username gitlab_username
  uid node['gitlab']['user']['uid']
  ugid gitlab_group
  groupname gitlab_group
  gid node['gitlab']['user']['gid']
  shell node['gitlab']['user']['shell']
  home gitlab_home
  manage node['gitlab']['manage-accounts']['enable']
end

# Configure Git settings for the GitLab user
template File.join(gitlab_home, ".gitconfig") do
  source "gitconfig.erb"
  owner gitlab_username
  group gitlab_group
  mode "0644"
  variables(user_options: node['gitlab']['user'],
            system_core_options: node.dig('gitlab', 'omnibus-gitconfig', 'system', 'core') || [])
end

# The directory will remain empty in Omnibus GitLab use-case.
# We still need it to prevent bundler printing warning.
directory File.join(gitlab_home, ".bundle") do
  owner gitlab_username
  group gitlab_group
end
