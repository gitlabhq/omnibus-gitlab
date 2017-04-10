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

include_recipe 'gitlab::prometheus_user'

directory prometheus_dir do
  owner prometheus_user
  mode '0750'
  recursive true
end

directory prometheus_log_dir do
  owner prometheus_user
  mode '0700'
  recursive true
end

# Include Prometheus server self-scrape.
node.default['gitlab']['prometheus']['scrape_configs'] << {
  'job_name' => 'prometheus',
  'static_configs' => [
    'targets' => [node['gitlab']['prometheus']['listen_address']],
  ],
}

if node['gitlab']['prometheus']['monitor_kubernetes']
  node.default['gitlab']['prometheus']['scrape_configs'] << {
    'job_name' => 'kubernetes-nodes',
    'scheme' => 'https',
    'tls_config' => {
      'ca_file' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
      'insecure_skip_verify' => 'true',
    },
    'bearer_token_file' => '/var/run/secrets/kubernetes.io/serviceaccount/token',
    'kubernetes_sd_configs' => [
      {
        'role' => 'node',
        'api_server' => 'https://kubernetes.default.svc:443',
        'tls_config' => {
          'ca_file' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
        },
        'bearer_token_file' => '/var/run/secrets/kubernetes.io/serviceaccount/token',
      },
    ],
    'relabel_configs' => [
      {
        'action' => 'labelmap',
        'regex' => '__meta_kubernetes_node_label_(.+)',
      },
    ],
    'metric_relabel_configs' => [
      {
        'source_labels' => ['pod_name'],
        'target_label' => 'environment',
        'regex' => '(.+)-.+-.+',
      },
    ],
  }
end

file 'Prometheus config' do
  path File.join(prometheus_dir, 'prometheus.yml')
  content lazy { Prometheus.hash_to_yaml({
    'global' => {
      'scrape_interval' => "#{node['gitlab']['prometheus']['scrape_interval']}s",
      'scrape_timeout' => "#{node['gitlab']['prometheus']['scrape_timeout']}s",
    },
    'scrape_configs' => node['gitlab']['prometheus']['scrape_configs'],
  }) }
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
