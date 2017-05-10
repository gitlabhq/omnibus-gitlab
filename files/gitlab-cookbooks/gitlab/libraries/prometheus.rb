#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require_relative 'postgresql.rb'
require_relative 'redis.rb'

require 'yaml'
require 'json'

module Prometheus
  class << self
    def services
      %w(
        prometheus
        node-exporter
        redis-exporter
        postgres-exporter
        gitlab-monitor
      )
    end

    def parse_variables
      parse_exporter_enabled
      parse_scrape_configs
      parse_flags
    end

    def parse_exporter_enabled
      # Disable exporters by default if their service is not managed on this node
      Gitlab['postgres_exporter']['enable'] = Postgresql.postgresql_managed? if Gitlab['postgres_exporter']['enable'].nil?
      Gitlab['redis_exporter']['enable'] = Redis.redis_managed? if Gitlab['redis_exporter']['enable'].nil?
    end

    def parse_flags
      parse_prometheus_flags
      parse_node_exporter_flags
      parse_postgres_exporter_flags
      parse_redis_exporter_flags
    end

    def parse_prometheus_flags
      default_config = Gitlab['node']['gitlab']['prometheus'].to_hash
      user_config = Gitlab['prometheus']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      chunk_encoding_version = user_config['chunk_encoding_version'] || default_config['chunk_encoding_version']
      target_heap_size = user_config['target_heap_size'] || default_config['target_heap_size']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'storage.local.path' => File.join(home_directory, 'data'),
        'storage.local.chunk-encoding-version' => chunk_encoding_version.to_s,
        'storage.local.target-heap-size' => target_heap_size.to_s,
        'config.file' => File.join(home_directory, 'prometheus.yml')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['prometheus']['flags'] = default_config['flags']
    end

    def parse_node_exporter_flags
      default_config = Gitlab['node']['gitlab']['node-exporter'].to_hash
      user_config = Gitlab['node_exporter']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'collector.textfile.directory' => File.join(home_directory, 'textfile_collector')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['node_exporter']['flags'] = default_config['flags']
    end

    def parse_redis_exporter_flags
      default_config = Gitlab['node']['gitlab']['redis-exporter'].to_hash
      user_config = Gitlab['redis_exporter']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'redis.addr' => "unix://#{Gitlab['node']['gitlab']['gitlab-rails']['redis_socket']}"
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['redis_exporter']['flags'] = default_config['flags']
    end

    def parse_postgres_exporter_flags
      default_config = Gitlab['node']['gitlab']['postgres-exporter'].to_hash
      user_config = Gitlab['postgres_exporter']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['postgres_exporter']['flags'] = default_config['flags']
    end

    def parse_scrape_configs
      # Don't parse if prometheus is explicitly disabled
      return if Gitlab['prometheus']['enable'] == false
      gitlab_monitor_scrape_configs
      exporter_scrape_config('node')
      exporter_scrape_config('postgres')
      exporter_scrape_config('redis')
      prometheus_scrape_configs
    end

    def gitlab_monitor_scrape_configs
      # Don't parse if gitlab_monitor is explicitly disabled
      return if Gitlab['gitlab_monitor']['enable'] == false

      default_config = Gitlab['node']['gitlab']['gitlab-monitor'].to_hash
      user_config = Gitlab['gitlab_monitor']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      listen_port = user_config['listen_port'] || default_config['listen_port']
      prometheus_target = [ listen_address, listen_port ].join(':')

      # Include gitlab-monitor defaults scrape config.
      database =  {
                    'job_name' => 'gitlab_monitor_database',
                    'metrics_path' => '/database',
                    'static_configs' => [
                      'targets' => [prometheus_target],
                    ]
                  }
      sidekiq = {
                  'job_name' => 'gitlab_monitor_sidekiq',
                  'metrics_path' => '/sidekiq',
                  'static_configs' => [
                    'targets' => [prometheus_target],
                  ]
                }
      process = {
                  'job_name' => 'gitlab_monitor_process',
                  'metrics_path' => '/process',
                  'static_configs' => [
                    'targets' => [prometheus_target],
                  ]
                }

      default_scrape_configs = [] << database << sidekiq << process << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def exporter_scrape_config(exporter)
      # Don't parse if exporter is explicitly disabled
      return if Gitlab["#{exporter}_exporter"]['enable'] == false

      default_config = Gitlab['node']['gitlab']["#{exporter}-exporter"].to_hash
      user_config = Gitlab["#{exporter}_exporter"]

      listen_address = user_config['listen_address'] || default_config['listen_address']

      default_config = {
                          'job_name' => exporter,
                          'static_configs' => [
                            'targets' => [listen_address],
                          ],
                        }

      default_scrape_configs = [] << default_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def prometheus_scrape_configs
      default_config = Gitlab['node']['gitlab']['prometheus'].to_hash
      user_config = Gitlab['prometheus']

      listen_address = user_config['listen_address'] || default_config['listen_address']

      prometheus = {
                'job_name' => 'prometheus',
                'static_configs' => [
                  'targets' => [listen_address],
                ],
              }

      k8s_nodes = {
          'job_name' => 'kubernetes-nodes',
          'scheme' => 'https',
          'tls_config' => {
            'ca_file' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
            'insecure_skip_verify' => true,
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

      default_scrape_configs = [] << prometheus << Gitlab['prometheus']['scrape_configs']
      default_scrape_configs = default_scrape_configs << k8s_nodes unless Gitlab['prometheus']['monitor_kubernetes'] == false
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    # This is a hack to avoid chef's to_yaml issues.
    def hash_to_yaml(hash)
      mutable_hash = JSON.parse(hash.dup.to_json)
      mutable_hash.to_yaml
    end
  end
end
