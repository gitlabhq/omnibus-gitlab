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

gitlab_username = node['gitlab']['user']['username']
gitlab_group = node['gitlab']['user']['group']
gitlab_home = node['gitlab']['user']['home']

directory gitlab_home do
  recursive true
end

# Create the group for the GitLab user
group gitlab_group do
  gid node['gitlab']['user']['gid']
  system true
end

# Create the GitLab user
user gitlab_username do
  shell node['gitlab']['user']['shell']
  home gitlab_home
  uid node['gitlab']['user']['uid']
  gid gitlab_group
  system true
end

# Configure Git settings for the GitLab user
template File.join(gitlab_home, ".gitconfig") do
  source "gitconfig.erb"
  owner gitlab_username
  group gitlab_group
  mode "0644"
  variables(node['gitlab']['user'].to_hash)
end
