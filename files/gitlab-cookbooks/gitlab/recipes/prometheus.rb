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
omnibus_helper = OmnibusHelper.new(node)
prometheus_helper = PrometheusHelper.new(node)
prometheus_user = account_helper.prometheus_user
prometheus_log_dir = node['gitlab']['prometheus']['log_directory']
prometheus_dir = node['gitlab']['prometheus']['home']
prometheus_rules_dir = node['gitlab']['prometheus']['rules_directory']
prometheus_static_etc_dir = node['gitlab']['prometheus']['env_directory']

binary, rule_extension = prometheus_helper.binary_and_rules

include_recipe 'gitlab::prometheus_user'

directory prometheus_dir do
  owner prometheus_user
  mode '0750'
  recursive true
end

directory prometheus_rules_dir do
  owner prometheus_user
  mode '0750'
  recursive true
end

directory prometheus_log_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

directory prometheus_static_etc_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

env_dir prometheus_static_etc_dir do
  variables node['gitlab']['prometheus']['env']
  notifies :restart, "service[prometheus]"
end

link "Link prometheus executable to correct binary" do
  target_file "#{node['package']['install-dir']}/embedded/bin/prometheus"
  to "#{node['package']['install-dir']}/embedded/bin/#{binary}"

  notifies :restart, 'service[prometheus]', :immediately if omnibus_helper.should_notify?("prometheus")
end

configuration = Prometheus.hash_to_yaml({
                                          'global' => {
                                            'scrape_interval' => "#{node['gitlab']['prometheus']['scrape_interval']}s",
                                            'scrape_timeout' => "#{node['gitlab']['prometheus']['scrape_timeout']}s",
                                          },
                                          'remote_read' => node['gitlab']['prometheus']['remote_read'],
                                          'remote_write' => node['gitlab']['prometheus']['remote_write'],
                                          'rule_files' => node['gitlab']['prometheus']['rules_files'],
                                          'scrape_configs' => node['gitlab']['prometheus']['scrape_configs'],
                                          'alerting' => {
                                            'alertmanagers' => node['gitlab']['prometheus']['alertmanagers'],
                                          }
                                        })

execute 'reload prometheus' do
  command %(/opt/gitlab/bin/gitlab-ctl hup prometheus)
  retries 20
  action :nothing
  only_if { prometheus_helper.is_running? }
end

file 'Prometheus config' do
  path File.join(prometheus_dir, 'prometheus.yml')
  content configuration
  owner prometheus_user
  mode '0644'
  notifies :run, 'execute[reload prometheus]'
end

runtime_flags = prometheus_helper.flags('prometheus')
runit_service 'prometheus' do
  options({
    log_directory: prometheus_log_dir,
    flags: runtime_flags,
    env_dir: prometheus_static_etc_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(
    node['gitlab']['prometheus'].to_hash
  )
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start prometheus" do
    retries 20
  end
end

template File.join(prometheus_rules_dir, 'gitlab.rules') do
  source "prometheus/rules/gitlab.#{rule_extension}"
  owner prometheus_user
  mode '0644'
  notifies :run, 'execute[reload prometheus]'
  only_if { node['gitlab']['prometheus']['enable'] }
end

template File.join(prometheus_rules_dir, 'node.rules') do
  source "prometheus/rules/node.#{rule_extension}"
  owner prometheus_user
  mode '0644'
  notifies :run, 'execute[reload prometheus]'
  only_if { node['gitlab']['prometheus']['enable'] }
end
