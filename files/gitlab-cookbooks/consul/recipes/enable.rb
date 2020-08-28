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
consul_helper = ConsulHelper.new(node)

gitlab_consul_static_etc_dir = node['consul']['env_directory']

account "Consul user and group" do
  username account_helper.consul_user
  uid node['consul']['uid']
  ugid account_helper.consul_group
  groupname account_helper.consul_group
  gid node['consul']['gid']
  home node['consul']['dir']
  manage node['gitlab']['manage-accounts']['enable']
end

directory node['consul']['dir'] do
  owner account_helper.consul_user
end

directory gitlab_consul_static_etc_dir do
  owner account_helper.consul_user
  mode '0700'
  recursive true
end

env_dir gitlab_consul_static_etc_dir do
  variables node['consul']['env']
end

%w(
  config_dir
  data_dir
  log_directory
  script_directory
).each do |dir|
  directory node['consul'][dir] do
    owner account_helper.consul_user
  end
end

file "#{node['consul']['dir']}/config.json" do
  content consul_helper.configuration
  owner account_helper.consul_user
  mode '0600'
  notifies :run, 'execute[reload consul]'
end

include_recipe 'consul::configure_services'

include_recipe 'consul::watchers'

include_recipe 'consul::enable_daemon'
