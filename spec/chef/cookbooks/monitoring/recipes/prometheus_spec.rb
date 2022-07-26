require 'chef_helper'

RSpec.describe 'monitoring::prometheus' do
  let(:prometheus_scrape_config) do
    {
      job_name: "prometheus",
      static_configs: [
        {
          targets: [
            "localhost:9090"
          ]
        }
      ]
    }
  end
  let(:nginx_scrape_config) do
    {
      job_name: "nginx",
      static_configs: [
        {
          targets: [
            "localhost:8060"
          ]
        }
      ]
    }
  end
  let(:redis_scrape_config) do
    {
      job_name: "redis",
      static_configs: [
        {
          targets: [
            "localhost:9121"
          ]
        }
      ]
    }
  end
  let(:postgres_scrape_config) do
    {
      job_name: "postgres",
      static_configs: [
        {
          targets: [
            "localhost:9187"
          ]
        }
      ]
    }
  end
  let(:node_scrape_config) do
    {
      job_name: "node",
      static_configs: [
        {
          targets: [
            "localhost:9100"
          ]
        }
      ]
    }
  end
  let(:workhorse_scrape_config) do
    {
      job_name: "gitlab-workhorse",
      static_configs: [
        {
          targets: [
            "localhost:9229"
          ]
        }
      ]
    }
  end
  let(:rails_scrape_config) do
    {
      job_name: "gitlab-rails",
      metrics_path: "/-/metrics",
      static_configs: [
        {
          targets: [
            "127.0.0.1:8080"
          ]
        }
      ],
      relabel_configs: [
        {
          source_labels: [
            "__address__"
          ],
          regex: "127.0.0.1:(.*)",
          replacement: "localhost:$1",
          target_label: "instance"
        }
      ]
    }
  end
  let(:sidekiq_scrape_config) do
    {
      job_name: "gitlab-sidekiq",
      static_configs: [
        {
          targets: [
            "127.0.0.1:8082"
          ]
        }
      ],
      relabel_configs: [
        {
          source_labels: [
            "__address__"
          ],
          regex: "127.0.0.1:(.*)",
          replacement: "localhost:$1",
          target_label: "instance"
        }
      ]
    }
  end
  let(:registry_scrape_config) do
    {
      job_name: "registry",
      static_configs: [
        {
          targets: [
            "localhost:5001"
          ]
        }
      ]
    }
  end
  let(:gitlab_exporter_scrape_config) do
    [
      {
        job_name: "gitlab_exporter_database",
        metrics_path: "/database",
        static_configs: [
          {
            targets: [
              "localhost:9168"
            ]
          }
        ]
      },
      {
        job_name: "gitlab_exporter_sidekiq",
        metrics_path: "/sidekiq",
        static_configs: [
          {
            targets: [
              "localhost:9168"
            ]
          }
        ]
      },
      {
        job_name: "gitlab_exporter_ruby",
        metrics_path: "/ruby",
        static_configs: [
          {
            targets: [
              "localhost:9168"
            ]
          }
        ]
      }
    ]
  end
  let(:gitaly_scrape_config) do
    {
      job_name: "gitaly",
      static_configs: [
        {
          targets: [
            "localhost:9236"
          ]
        }
      ]
    }
  end
  let(:k8s_scrape_config) do
    [
      {
        job_name: "kubernetes-cadvisor",
        scheme: "https",
        tls_config: {
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          insecure_skip_verify: true
        },
        bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token",
        kubernetes_sd_configs: [
          {
            role: "node",
            api_server: "https://kubernetes.default.svc:443",
            tls_config: {
              ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
            },
            bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
        ],
        relabel_configs: [
          {
            action: "labelmap",
            regex: "__meta_kubernetes_node_label_(.+)"
          },
          {
            target_label: "__address__",
            replacement: "kubernetes.default.svc:443"
          },
          {
            source_labels: [
              "__meta_kubernetes_node_name"
            ],
            regex: "(.+)",
            target_label: "__metrics_path__",
            replacement: "/api/v1/nodes/${1}/proxy/metrics/cadvisor",
          }
        ],
        metric_relabel_configs: [
          {
            source_labels: [
              "pod_name"
            ],
            target_label: "environment",
            regex: "(.+)-.+-.+"
          }
        ]
      },
      {
        job_name: "kubernetes-nodes",
        scheme: "https",
        tls_config: {
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          insecure_skip_verify: true
        },
        bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token",
        kubernetes_sd_configs: [
          {
            role: "node",
            api_server: "https://kubernetes.default.svc:443",
            tls_config: {
              ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
            },
            bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
        ],
        relabel_configs: [
          {
            action: "labelmap",
            regex: "__meta_kubernetes_node_label_(.+)"
          },
          {
            target_label: "__address__",
            replacement: "kubernetes.default.svc:443"
          },
          {
            source_labels: [
              "__meta_kubernetes_node_name"
            ],
            regex: "(.+)",
            target_label: "__metrics_path__",
            replacement: "/api/v1/nodes/${1}/proxy/metrics",
          }
        ],
        metric_relabel_configs: [
          {
            source_labels: [
              "pod_name"
            ],
            target_label: "environment",
            regex: "(.+)-.+-.+"
          }
        ]
      },
      {
        job_name: "kubernetes-pods",
        tls_config: {
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          insecure_skip_verify: true
        },
        bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token",
        kubernetes_sd_configs: [
          {
            role: "pod",
            api_server: "https://kubernetes.default.svc:443",
            tls_config: {
              ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
            },
            bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
        ],
        relabel_configs: [
          {
            source_labels: [
              "__meta_kubernetes_pod_annotation_prometheus_io_scrape"
            ],
            action: "keep",
            regex: "true"
          },
          {
            source_labels: [
              "__meta_kubernetes_pod_annotation_prometheus_io_path"
            ],
            action: "replace",
            target_label: "__metrics_path__",
            regex: "(.+)"
          },
          {
            source_labels: [
              "__address__",
              "__meta_kubernetes_pod_annotation_prometheus_io_port"
            ],
            action: "replace",
            regex: "([^:]+)(?::[0-9]+)?;([0-9]+)",
            replacement: "$1:$2",
            target_label: "__address__"
          },
          {
            action: "labelmap",
            regex: "__meta_kubernetes_pod_label_(.+)"
          },
          {
            source_labels: [
              "__meta_kubernetes_namespace"
            ],
            action: "replace",
            target_label: "kubernetes_namespace"
          },
          {
            source_labels: [
              "__meta_kubernetes_pod_name"
            ],
            action: "replace",
            target_label: "kubernetes_pod_name"
          }
        ]
      }
    ]
  end

  let(:expected_prometheus_yml) do
    {
      global: {
        scrape_interval: "15s",
        scrape_timeout: "15s",
        external_labels: {}
      },
      remote_read: [],
      remote_write: [],
      rule_files: [
        "/var/opt/gitlab/prometheus/rules/*.rules"
      ],
      scrape_configs: [
        prometheus_scrape_config,
        nginx_scrape_config,
        redis_scrape_config,
        postgres_scrape_config,
        node_scrape_config,
        workhorse_scrape_config,
        rails_scrape_config,
        sidekiq_scrape_config,
        registry_scrape_config,
        gitlab_exporter_scrape_config,
        gitaly_scrape_config,
        k8s_scrape_config
      ].flatten,
      alerting: {
        alertmanagers: [
          {
            static_configs: [
              {
                targets: [
                  "localhost:9093"
                ]
              }
            ]
          }
        ]
      }
    }
  end
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:prometheus_yml_template) { chef_run.file('/var/opt/gitlab/prometheus/prometheus.yml') }
  let(:prometheus_yml_file_content) { ChefSpec::Renderer.new(chef_run, prometheus_yml_template).content }
  let(:prometheus_yml) { YAML.safe_load(prometheus_yml_file_content, [], [], true, symbolize_names: true) }

  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when prometheus is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/prometheus/log/config') }

    before do
      stub_gitlab_rb(
        alertmanager: {
          enable: true
        },
        prometheus: {
          enable: true
        },
        gitlab_exporter: {
          enable: true
        },
        registry: {
          enable: true,
          debug_addr: 'localhost:5001'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'prometheus', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/prometheus/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content { |content|
                            expect(content).to match(/exec chpst -P/)
                            expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/prometheus/)
                            expect(content).to match(/prometheus.yml/)
                          }

      expect(prometheus_yml).to match(expected_prometheus_yml)

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/prometheus/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0750'
      )
    end

    it 'should create a gitlab-prometheus user and group' do
      expect(chef_run).to create_account('Prometheus user and group').with(username: 'gitlab-prometheus', groupname: 'gitlab-prometheus')
    end

    it 'sets a default listen address' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/web.listen-address=localhost:9090/)
    end
  end

  context 'by default' do
    context 'with user provided settings' do
      it 'configures puma job' do
        expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
          .with_content(%r{- job_name: gitlab-rails\s+metrics_path: "/-/metrics"\s+static_configs:\s+- targets:\s+- 127.0.0.1:8080})
      end
    end
  end

  context 'when exporter scheme is https' do
    context 'when gitlab-exporter responds using TLS' do
      before do
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?).with(%r{/tmp/server.(crt|key)}).and_return(true)

        stub_gitlab_rb(
          gitlab_exporter: {
            enable: true,
            tls_enabled: true,
            tls_cert_path: '/tmp/server.crt',
            tls_key_path: '/tmp/server.key',
          }
        )
      end

      it 'populates the gitlab-exporter scrape config properly' do
        expected_config = gitlab_exporter_scrape_config.dup
        expected_config.each do |config|
          config.merge!(
            scheme: 'https',
            tls_config: {
              server_name: 'localhost',
              insecure_skip_verify: false
            }
          )
        end

        generated_config = prometheus_yml[:scrape_configs].select { |item| item[:job_name].start_with?('gitlab_exporter') }
        expect(generated_config).to eq(expected_config)
      end
    end

    context 'when puma responds using TLS' do
      before do
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?).with(%r{/tmp/server.(crt|key)}).and_return(true)

        stub_gitlab_rb(
          puma: {
            ssl_listen: '127.0.0.1',
            ssl_port: 9111,
            ssl_certificate: '/tmp/server.crt',
            ssl_certificate_key: '/tmp/server.key',
          }
        )
      end

      it 'populates the rails scrape config properly' do
        expected_config = rails_scrape_config.dup
        expected_config.merge!(
          scheme: 'https',
          tls_config: {
            server_name: 'localhost',
            insecure_skip_verify: false
          },
          static_configs: [
            targets: [
              "127.0.0.1:9111"
            ]
          ]
        )

        generated_config = prometheus_yml[:scrape_configs].find { |item| item[:job_name] == 'gitlab-rails' }
        expect(generated_config).to eq(expected_config)
      end
    end
  end

  context 'rules directory' do
    context 'default settings' do
      it 'creates rules directory in correct location' do
        expect(chef_run).to create_directory("/var/opt/gitlab/prometheus/rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus/rules/node.rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus/rules/gitlab.rules")
      end
    end

    context 'user specified home directory' do
      before do
        stub_gitlab_rb(
          prometheus: {
            home: "/var/opt/gitlab/prometheus-bak"
          }
        )
      end

      it 'creates rules directory in correct location' do
        expect(chef_run).to create_directory("/var/opt/gitlab/prometheus-bak/rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus-bak/rules/node.rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus-bak/rules/gitlab.rules")
      end
    end

    context 'user specified rules directory' do
      before do
        stub_gitlab_rb(
          prometheus: {
            rules_directory: "/var/opt/gitlab/prometheus/alert-rules"
          }
        )
      end

      it 'creates rules directory in correct location' do
        expect(chef_run).to create_directory("/var/opt/gitlab/prometheus/alert-rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus/alert-rules/node.rules")
        expect(chef_run).to render_file("/var/opt/gitlab/prometheus/alert-rules/gitlab.rules")
      end
    end
  end

  include_examples "consul service discovery", "prometheus", "prometheus"
end
