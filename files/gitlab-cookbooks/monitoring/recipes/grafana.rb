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
grafana_log_dir = node['monitoring']['grafana']['log_directory']
grafana_dir = node['monitoring']['grafana']['home']
grafana_assets_dir = '/opt/gitlab/embedded/service/grafana'
grafana_config = File.join(grafana_dir, 'grafana.ini')
grafana_static_etc_dir = node['monitoring']['grafana']['env_directory']
grafana_provisioning_dir = File.join(grafana_dir, 'provisioning')
grafana_provisioning_dashboards_dir = File.join(grafana_provisioning_dir, 'dashboards')
grafana_provisioning_datasources_dir = File.join(grafana_provisioning_dir, 'datasources')
grafana_provisioning_notifiers_dir = File.join(grafana_provisioning_dir, 'notifiers')

external_url = if Gitlab['external_url']
                 Gitlab['external_url'].to_s.chomp('/')
               else
                 'http://localhost'
               end

# grafana runs under the prometheus user account. If prometheus is
# disabled, it's up to this recipe to create the account
include_recipe 'monitoring::user'

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

directory grafana_provisioning_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory grafana_provisioning_dashboards_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory grafana_provisioning_datasources_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory grafana_provisioning_notifiers_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

file File.join(grafana_dir, 'CVE_reset_status') do
  action :delete
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

if !node['monitoring']['grafana']['gitlab_secret'] && !node['monitoring']['grafana']['gitlab_application_id']
  ruby_block "authorize Grafana with GitLab" do
    block do
      GrafanaHelper.authorize_with_gitlab(external_url)
    end
    # Try connecting to GitLab only if it is enabled and on this node
    only_if { node['gitlab']['gitlab-rails']['enable'] }
  end
end

ruby_block "populate Grafana configuration options" do
  block do
    node.consume_attributes(
      { 'monitoring' => { 'grafana' => Gitlab.hyphenate_config_keys['monitoring']['grafana'] } }
    )
  end
end

env_dir grafana_static_etc_dir do
  variables node['monitoring']['grafana']['env']
  notifies :restart, 'runit_service[grafana]'
end

template grafana_config do
  source 'grafana_ini.erb'
  variables lazy {
    {
      'external_url' => external_url,
      'data_path' => File.join(node['monitoring']['grafana']['home'], 'data'),
    }.merge(node['monitoring']['grafana'])
  }
  owner prometheus_user
  mode '0644'
  notifies :restart, 'runit_service[grafana]'
  only_if { node['monitoring']['grafana']['enable'] }
end

dashboards = {
  'apiVersion' => 1,
  'providers' => node['monitoring']['grafana']['dashboards']
}

file File.join(grafana_provisioning_dashboards_dir, 'gitlab_dashboards.yml') do
  content Prometheus.hash_to_yaml(dashboards)
  owner prometheus_user
  mode '0644'
  notifies :restart, 'runit_service[grafana]'
end

datasources = {
  'apiVersion' => 1,
  'datasources' => node['monitoring']['grafana']['datasources']
}

file File.join(grafana_provisioning_datasources_dir, 'gitlab_datasources.yml') do
  content Prometheus.hash_to_yaml(datasources)
  owner prometheus_user
  mode '0644'
  notifies :restart, 'runit_service[grafana]'
end

runit_service 'grafana' do
  options({
    log_directory: grafana_log_dir,
    config: grafana_config,
    env_dir: grafana_static_etc_dir,
    working_dir: grafana_dir,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(
    node['monitoring']['grafana'].to_hash
  )
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start grafana" do
    retries 20
  end
end
