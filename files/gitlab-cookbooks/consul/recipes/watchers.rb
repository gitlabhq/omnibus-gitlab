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

node['consul']['watchers'].each do |watcher|
  config = consul_helper.watcher_config(watcher)

  file "#{node['consul']['config_dir']}/watcher_#{watcher}.json" do
    content config.to_json
    owner account_helper.postgresql_user
  end

  config[:watches].each do |watch|
    template "#{node['consul']['script_directory']}/#{consul_helper.watcher_handler(watch[:service])}" do
      source "watcher_scripts/#{node['consul']['watcher_config'][watch[:service]][:handler]}.erb"
      variables node['consul'].to_hash
      mode 0555
    end
  end
end

# Watcher specific settings
if node['consul']['watchers'].include?('postgresql')
  node.default['gitlab']['pgbouncer']['databases_ini'] = '/var/opt/gitlab/consul/databases.ini'
  node.default['gitlab']['pgbouncer']['databases_json'] = '/var/opt/gitlab/consul/databases.json'
  node.default['gitlab']['pgbouncer']['databases_ini_user'] = 'gitlab-consul'
end
