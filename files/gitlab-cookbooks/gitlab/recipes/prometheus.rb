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
prometheus_user = account_helper.prometheus_user
prometheus_log_dir = node['gitlab']['prometheus']['log_directory']
prometheus_dir = node['gitlab']['prometheus']['home']
prometheus_rules_dir = node['gitlab']['prometheus']['rules_directory']

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

configuration = Prometheus.hash_to_yaml({
                                          'global' => {
                                            'scrape_interval' => "#{node['gitlab']['prometheus']['scrape_interval']}s",
                                            'scrape_timeout' => "#{node['gitlab']['prometheus']['scrape_timeout']}s",
                                          },
                                          'remote_read' => node['gitlab']['prometheus']['remote_read'],
                                          'remote_write' => node['gitlab']['prometheus']['remote_write'],
                                          'rule_files' => node['gitlab']['prometheus']['rules_files'],
                                          'scrape_configs' => node['gitlab']['prometheus']['scrape_configs'],
                                        })

file 'Prometheus config' do
  path File.join(prometheus_dir, 'prometheus.yml')
  content configuration
  owner prometheus_user
  mode '0644'
  notifies :restart, 'service[prometheus]'
end

runtime_flags = PrometheusHelper.new(node).flags('prometheus')
runit_service 'prometheus' do
  options({
    log_directory: prometheus_log_dir,
    flags: runtime_flags
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

template File.join(prometheus_rules_dir, 'node.rules') do
  source 'prometheus/rules/node.rules.erb'
  owner prometheus_user
  mode '0644'
  only_if { node['gitlab']['prometheus']['enable'] }
end
