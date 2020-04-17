#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

include_recipe 'postgresql::directory_locations'

account "Postgresql user and group" do
  username postgresql_username
  uid node['postgresql']['uid']
  ugid postgresql_username
  groupname postgresql_group
  gid node['postgresql']['gid']
  shell node['postgresql']['shell']
  home node['postgresql']['home']
  manage node['gitlab']['manage-accounts']['enable']
end

directory node['postgresql']['home'] do
  owner postgresql_username
  mode "0755"
  recursive true
end

file File.join(node['postgresql']['home'], ".profile") do
  owner postgresql_username
  mode "0600"
  content <<-EOH
PATH=#{node['postgresql']['user_path']}
  EOH
end
