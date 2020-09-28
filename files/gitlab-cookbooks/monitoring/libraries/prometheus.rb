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

require_relative 'prometheus_helper.rb'
require_relative '../../gitlab/libraries/postgresql.rb'
require_relative '../../gitlab/libraries/redis.rb'

require 'yaml'
require 'json'

module Prometheus
  class << self
    def services
      Services.find_by_group('monitoring').map { |name, _| name.tr('_', '-') }
    end

    def parse_variables
      parse_exporter_enabled
      parse_monitoring_enabled
      parse_prometheus_alertmanager_config
      parse_alertmanager_config
      parse_scrape_configs
      parse_rules_files
      parse_flags
    end

    def parse_monitoring_enabled
      # Disabled monitoring if it has been explicitly set to false
      Services.disable_group('monitoring', include_system: true) if Gitlab['prometheus_monitoring']['enable'] == false
    end

    def parse_exporter_enabled
      # Disable exporters by default if their service is not managed on this node
      Services.set_enable('postgres_exporter', Postgresql.postgresql_managed?) if Gitlab['postgres_exporter']['enable'].nil?
      Services.set_enable('redis_exporter', Redis.redis_managed?) if Gitlab['redis_exporter']['enable'].nil?
    end

    def parse_flags
      parse_prometheus_flags
      parse_alertmanager_flags
      parse_node_exporter_flags
      parse_postgres_exporter_flags
      parse_redis_exporter_flags
    end

    def parse_prometheus_flags
      default_config = Gitlab['node']['monitoring']['prometheus'].to_hash
      user_config = Gitlab['prometheus']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'storage.tsdb.path' => File.join(home_directory, 'data'),
        'config.file' => File.join(home_directory, 'prometheus.yml')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['prometheus']['flags'] = default_config['flags']
    end

    def parse_alertmanager_flags
      default_config = Gitlab['node']['monitoring']['alertmanager'].to_hash
      user_config = Gitlab['alertmanager']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']

      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'storage.path' => File.join(home_directory, 'data'),
        'config.file' => File.join(home_directory, 'alertmanager.yml')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['alertmanager']['flags'] = default_config['flags']
    end

    def parse_node_exporter_flags
      default_config = Gitlab['node']['monitoring']['node-exporter'].to_hash
      user_config = Gitlab['node_exporter']
      runit_config = Gitlab['node']['runit'].to_hash

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'collector.mountstats' => true,
        'collector.runit' => true,
        'collector.runit.servicedir' => runit_config['sv_dir'],
        'collector.textfile.directory' => File.join(home_directory, 'textfile_collector')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['node_exporter']['flags'] = default_config['flags']
    end

    def parse_redis_exporter_flags
      default_config = Gitlab['node']['monitoring']['redis-exporter'].to_hash
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
      default_config = Gitlab['node']['monitoring']['postgres-exporter'].to_hash
      user_config = Gitlab['postgres_exporter']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'extend.query-path' => File.join(home_directory, 'queries.yaml'),
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['postgres_exporter']['flags'] = default_config['flags']
    end

    def parse_prometheus_alertmanager_config
      prom_user_config = Gitlab['prometheus']
      default_config = Gitlab['node']['monitoring']['alertmanager'].to_hash
      user_config = Gitlab['alertmanager']

      if Services.enabled?('alertmanager')
        listen_address = user_config['listen_address'] || default_config['listen_address']
        default_am_config = [
          {
            'static_configs' => [
              {
                'targets' => [
                  listen_address
                ]
              }
            ]
          }
        ]
      else
        default_am_config = []
      end

      Gitlab['prometheus']['alertmanagers'] = prom_user_config['alertmanagers'] || default_am_config
    end

    def parse_alertmanager_config
      return unless Services.enabled?('alertmanager')

      user_config = Gitlab['alertmanager']
      rails_config = Gitlab['gitlab_rails']

      global = {}
      if rails_config['smtp_enable']
        global['smtp_from'] = rails_config['gitlab_email_from'] || 'unconfigured'
        global['smtp_smarthost'] = "#{rails_config['smtp_address'] || 'unconfigured'}:#{rails_config['smtp_port'] || '25'}"
        if %w(login plain).include?(rails_config['smtp_authentication'])
          global['smtp_auth_username'] = rails_config['smtp_user_name']
          global['smtp_auth_password'] = rails_config['smtp_password']
        end
      end
      global.merge!(user_config['global']) if user_config.key?('global')

      default_email_receiver = {
        'name' => 'default-receiver',
      }
      default_email_receiver['email_configs'] = ['to' => user_config['admin_email']] unless user_config['admin_email'].nil?

      default_inhibit_rules = [] << Gitlab['alertmanager']['inhibit_rules']
      default_receivers = [] << default_email_receiver << Gitlab['alertmanager']['receivers']
      default_routes = [] << Gitlab['alertmanager']['routes']
      default_templates = [] << Gitlab['alertmanager']['templates']

      Gitlab['alertmanager']['global'] = global
      Gitlab['alertmanager']['inhibit_rules'] = default_inhibit_rules.compact.flatten
      Gitlab['alertmanager']['receivers'] = default_receivers.compact.flatten
      Gitlab['alertmanager']['routes'] = default_routes.compact.flatten
      Gitlab['alertmanager']['templates'] = default_templates.compact.flatten
      Gitlab['alertmanager']['default_receiver'] = user_config['default_receiver'] || 'default-receiver'
    end

    def parse_rules_files
      # Don't parse if prometheus is explicitly disabled
      return unless Services.enabled?('prometheus')

      default_config = Gitlab['node']['monitoring']['prometheus'].to_hash
      user_config = Gitlab['prometheus']

      home_directory = user_config['home'] || default_config['home']
      rules_dir = user_config['rules_directory'] || File.join(home_directory, "rules")

      rules_files = user_config['rules_files'] || [File.join(rules_dir, '*.rules')]

      Gitlab['prometheus']['rules_directory'] = rules_dir
      Gitlab['prometheus']['rules_files'] = rules_files
    end

    def parse_scrape_configs
      # Don't parse if prometheus is explicitly disabled
      return unless Services.enabled?('prometheus')

      gitaly_scrape_config
      gitlab_exporter_scrape_configs
      registry_scrape_config
      sidekiq_scrape_config
      rails_scrape_configs
      workhorse_scrape_config
      exporter_scrape_config('node')
      exporter_scrape_config('postgres')
      exporter_scrape_config('redis')
      nginx_scrape_config
      prometheus_scrape_configs
    end

    def gitaly_scrape_config
      # Don't parse if gitaly is explicitly disabled
      return unless Services.enabled?('gitaly') || service_discovery

      default_config = Gitlab['node']['gitaly'].to_hash
      user_config = Gitlab['gitaly']

      # Don't enable a scrape config if the listen address is empty.
      return if user_config['prometheus_listen_addr'] && user_config['prometheus_listen_addr'].empty?

      if service_discovery
        scrape_config = {
          'job_name' => 'gitaly',
          'consul_sd_configs' => [{ 'services' => ['gitaly'] }]
        }
      else
        listen_address = user_config['prometheus_listen_addr'] || default_config['prometheus_listen_addr']

        scrape_config = {
          'job_name' => 'gitaly',
          'static_configs' => [
            'targets' => [listen_address],
          ]
        }
      end

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def gitlab_exporter_scrape_configs
      # Don't parse if gitlab_exporter is explicitly disabled
      return unless Services.enabled?('gitlab_exporter')

      default_config = Gitlab['node']['monitoring']['gitlab-exporter'].to_hash
      user_config = Gitlab['gitlab_exporter']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      listen_port = user_config['listen_port'] || default_config['listen_port']
      prometheus_target = [listen_address, listen_port].join(':')

      # Include gitlab-exporter defaults scrape config.
      database = {
        'job_name' => 'gitlab_exporter_database',
        'metrics_path' => '/database',
        'static_configs' => [
          'targets' => [prometheus_target],
        ]
      }
      sidekiq = {
        'job_name' => 'gitlab_exporter_sidekiq',
        'metrics_path' => '/sidekiq',
        'static_configs' => [
          'targets' => [prometheus_target],
        ]
      }
      process = {
        'job_name' => 'gitlab_exporter_process',
        'metrics_path' => '/process',
        'static_configs' => [
          'targets' => [prometheus_target],
        ]
      }

      default_scrape_configs = [] << database << sidekiq << process << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def registry_scrape_config
      # Don't parse if registry is explicitly disabled
      return unless Services.enabled?('registry')

      default_config = Gitlab['node']['registry'].to_hash
      user_config = Gitlab['registry']

      debug_addr = user_config['debug_addr'] || default_config['debug_addr']

      # Don't enable if there is no debug_addr
      return if debug_addr.nil?

      scrape_config = {
        'job_name' => 'registry',
        'static_configs' => [
          'targets' => [debug_addr],
        ]
      }

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def sidekiq_scrape_config
      # Don't parse if sidekiq is explicitly disabled
      return unless Services.enabled?('sidekiq') || Services.enabled?('sidekiq_cluster') || service_discovery

      if service_discovery
        scrape_config = {
          'job_name' => 'gitlab-sidekiq',
          'consul_sd_configs' => [{ 'services' => ['sidekiq'] }],
        }
      else
        default_config = Gitlab['node']['gitlab']['sidekiq'].to_hash
        user_config = Gitlab['sidekiq']

        # Don't enable unless the exporter is enabled
        return unless default_config['metrics_enabled'] || user_config['metrics_enabled']

        listen_address = user_config['listen_address'] || default_config['listen_address']
        listen_port = user_config['listen_port'] || default_config['listen_port']
        prometheus_target = [listen_address, listen_port].join(':')

        # Don't enable if the target is empty.
        return if prometheus_target.empty?

        scrape_config = {
          'job_name' => 'gitlab-sidekiq',
          'static_configs' => [
            'targets' => [prometheus_target],
          ],
          'relabel_configs' => [
            {
              "source_labels" => ["__address__"],
              "regex" => "127.0.0.1:(.*)",
              "replacement" => "localhost:$1",
              "target_label" => "instance"
            }
          ]
        }
      end

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def rails_scrape_configs
      return unless WebServerHelper.enabled? || service_discovery

      webserver_service = WebServerHelper.service_name
      default_config = Gitlab['node']['gitlab'][webserver_service].to_hash
      user_config = Gitlab[webserver_service]

      if service_discovery
        scrape_config = {
          'job_name' => 'gitlab-rails',
          'metrics_path' => '/-/metrics',
          'consul_sd_configs' => [{ 'services' => ['rails'] }]
        }
      else
        listen_address = user_config['listen'] || default_config['listen']
        listen_port = user_config['port'] || default_config['port']
        prometheus_target = [listen_address, listen_port].join(':')

        scrape_config = {
          'job_name' => 'gitlab-rails',
          'metrics_path' => '/-/metrics',
          'static_configs' => [
            'targets' => [prometheus_target],
          ],
          'relabel_configs' => [
            {
              "source_labels" => ["__address__"],
              "regex" => "127.0.0.1:(.*)",
              "replacement" => "localhost:$1",
              "target_label" => "instance"
            }
          ]
        }
      end

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def workhorse_scrape_config
      # Don't parse if workhorse is explicitly disabled
      return unless Services.enabled?('gitlab_workhorse') || service_discovery

      if service_discovery
        scrape_config = {
          'job_name' => 'gitlab-workhorse',
          'consul_sd_configs' => [{ 'services' => ['workhorse'] }]
        }
      else
        default_config = Gitlab['node']['gitlab']['gitlab-workhorse'].to_hash
        user_config = Gitlab['gitlab_workhorse']

        # Don't enable a scrape config if the listen address is empty.
        return if user_config['prometheus_listen_addr'] && user_config['prometheus_listen_addr'].empty?

        listen_address = user_config['prometheus_listen_addr'] || default_config['prometheus_listen_addr']

        scrape_config = {
          'job_name' => 'gitlab-workhorse',
          'static_configs' => [
            'targets' => [listen_address],
          ]
        }
      end

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def exporter_scrape_config(exporter)
      # Don't parse if exporter is explicitly disabled
      return unless Services.enabled?("#{exporter}_exporter") || service_discovery

      if service_discovery
        default_config = {
          'job_name' => exporter,
          'consul_sd_configs' => [{ 'services' => ["#{exporter}-exporter"] }]
        }
      else
        default_config = Gitlab['node']['monitoring']["#{exporter}-exporter"].to_hash
        user_config = Gitlab["#{exporter}_exporter"]

        listen_address = user_config['listen_address'] || default_config['listen_address']

        default_config = {
          'job_name' => exporter,
          'static_configs' => [
            'targets' => [listen_address],
          ],
        }
      end

      default_scrape_configs = [] << default_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def nginx_scrape_config
      # Don't parse if nginx is explicitly disabled.
      return unless Services.enabled?('nginx') || service_discovery

      if service_discovery
        scrape_config = {
          'job_name' => 'nginx',
          'consul_sd_configs' => [{ 'services' => ['nginx'] }]
        }
      else
        default_config = Gitlab['node']['gitlab']['nginx']['status'].to_hash
        user_config = Gitlab['nginx']

        if user_config['status']
          # Don't enable a scrape config if nginx status is disabled.
          return if user_config['status'].key?('enable') && user_config['status']['enable'] == false
          # Don't enable a scrape config if nginx vts is disabled.
          return if user_config['status'].key?('vts_enable') && user_config['status']['vts_enable'] == false

          listen_address = user_config['status']['fqdn'] || default_config['fqdn']
          port = user_config['status']['port'] || default_config['port']
        else
          listen_address = default_config['fqdn']
          port = default_config['port']
        end

        target = "#{listen_address}:#{port}"

        scrape_config = {
          'job_name' => 'nginx',
          'static_configs' => [
            'targets' => [target],
          ],
        }
      end

      default_scrape_configs = [] << scrape_config << Gitlab['prometheus']['scrape_configs']
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    def prometheus_scrape_configs
      if service_discovery
        prometheus = {
          'job_name' => 'prometheus',
          'consul_sd_configs' => [{ 'services' => ['prometheus'] }]
        }
      else
        default_config = Gitlab['node']['monitoring']['prometheus'].to_hash
        user_config = Gitlab['prometheus']

        listen_address = user_config['listen_address'] || default_config['listen_address']

        prometheus = {
          'job_name' => 'prometheus',
          'static_configs' => [
            'targets' => [listen_address],
          ],
        }
      end

      k8s_cadvisor = {
        'job_name' => 'kubernetes-cadvisor',
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
          {
            'target_label' => '__address__',
            'replacement' => 'kubernetes.default.svc:443',
          },
          {
            'source_labels' => ['__meta_kubernetes_node_name'],
            'regex' => '(.+)',
            'target_label' => '__metrics_path__',
            'replacement' => '/api/v1/nodes/${1}/proxy/metrics/cadvisor',
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
          {
            'target_label' => '__address__',
            'replacement' => 'kubernetes.default.svc:443',
          },
          {
            'source_labels' => ['__meta_kubernetes_node_name'],
            'regex' => '(.+)',
            'target_label' => '__metrics_path__',
            'replacement' => '/api/v1/nodes/${1}/proxy/metrics',
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

      k8s_pods = {
        'job_name' => 'kubernetes-pods',
        'tls_config' => {
          'ca_file' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          'insecure_skip_verify' => true,
        },
        'bearer_token_file' => '/var/run/secrets/kubernetes.io/serviceaccount/token',
        'kubernetes_sd_configs' => [
          {
            'role' => 'pod',
            'api_server' => 'https://kubernetes.default.svc:443',
            'tls_config' => {
              'ca_file' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
            },
            'bearer_token_file' => '/var/run/secrets/kubernetes.io/serviceaccount/token',
          },
        ],
        'relabel_configs' => [
          {
            'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scrape'],
            'action' => 'keep',
            'regex' => 'true',
          },
          {
            'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
            'action' => 'replace',
            'target_label' => '__metrics_path__',
            'regex' => '(.+)',
          },
          {
            'source_labels' => %w(__address__ __meta_kubernetes_pod_annotation_prometheus_io_port),
            'action' => 'replace',
            'regex' => '([^:]+)(?::[0-9]+)?;([0-9]+)',
            'replacement' => '$1:$2',
            'target_label' => '__address__',
          },
          {
            'action' => 'labelmap',
            'regex' => '__meta_kubernetes_pod_label_(.+)',
          },
          {
            'source_labels' => ['__meta_kubernetes_namespace'],
            'action' => 'replace',
            'target_label' => 'kubernetes_namespace',
          },
          {
            'source_labels' => ['__meta_kubernetes_pod_name'],
            'action' => 'replace',
            'target_label' => 'kubernetes_pod_name',
          },
        ],
      }

      default_scrape_configs = [] << prometheus << Gitlab['prometheus']['scrape_configs']
      default_scrape_configs = default_scrape_configs << k8s_cadvisor << k8s_nodes << k8s_pods unless Gitlab['prometheus']['monitor_kubernetes'] == false
      Gitlab['prometheus']['scrape_configs'] = default_scrape_configs.compact.flatten
    end

    # This is a hack to avoid chef's to_yaml issues.
    def hash_to_yaml(hash)
      mutable_hash = JSON.parse(hash.dup.to_json)
      mutable_hash.to_yaml
    end

    def service_discovery
      Services.enabled?('consul') && Gitlab['consul']['monitoring_service_discovery']
    end

    def service_discovery_action
      service_discovery ? :create : :delete
    end
  end
end
