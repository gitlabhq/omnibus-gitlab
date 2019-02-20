#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
prometheus_user = account_helper.prometheus_user
grafana_log_dir = node['gitlab']['grafana']['log_directory']
grafana_dir = node['gitlab']['grafana']['home']
grafana_assets_dir = '/opt/gitlab/embedded/service/grafana'
grafana_config = File.join(grafana_dir, 'grafana.ini')
grafana_static_etc_dir = node['gitlab']['grafana']['env_directory']

# grafana runs under the prometheus user account. If prometheus is
# disabled, it's up to this recipe to create the account
include_recipe 'gitlab::prometheus_user'

directory grafana_log_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory grafana_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

link File.join(grafana_dir, 'conf') do
  to File.join(grafana_assets_dir, 'conf')
end

link File.join(grafana_dir, 'public') do
  to File.join(grafana_assets_dir, 'public')
end

directory grafana_static_etc_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

env_dir grafana_static_etc_dir do
  variables node['gitlab']['grafana']['env']
  notifies :restart, 'service[grafana]'
end

template grafana_config do
  source 'grafana_ini.erb'
  owner prometheus_user
  mode '0644'
  notifies :restart, 'service[grafana]'
  only_if { node['gitlab']['grafana']['enable'] }
end

runit_service 'grafana' do
  options({
    log_directory: grafana_log_dir,
    config: grafana_config,
    env_dir: grafana_static_etc_dir,
    working_dir: grafana_dir,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(
    node['gitlab']['grafana'].to_hash
  )
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start grafana" do
    retries 20
  end
end
