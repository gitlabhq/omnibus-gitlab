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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('consul')

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
  script_directory
).each do |dir|
  directory node['consul'][dir] do
    owner account_helper.consul_user
  end
end

directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

file "#{node['consul']['dir']}/config.json" do
  content consul_helper.configuration
  owner account_helper.consul_user
  mode '0600'
  notifies :run, 'execute[reload consul]'
  notifies :run, 'ruby_block[consul config change]'
end

ruby_block 'consul config change' do
  block do
    message = <<~MESSAGE
      You have made a change to the consul configuration, and the daemon was reloaded.
      If the change isn't taking effect, restarting the consul agents may be required:
      https://docs.gitlab.com/ee/administration/consul.html#restart-consul
    MESSAGE
    LoggingHelper.warning(message)
  end
  action :nothing
end

include_recipe 'consul::configure_services'

include_recipe 'consul::watchers'

include_recipe 'consul::enable_daemon'
