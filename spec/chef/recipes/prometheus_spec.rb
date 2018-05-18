require 'chef_helper'

prometheus_yml_output = <<-PROMYML
  ---
  global:
    scrape_interval: 15s
    scrape_timeout: 15s
  scrape_configs:
  - job_name: prometheus
    static_configs:
    - targets:
      - localhost:9090
  - job_name: redis
    static_configs:
    - targets:
      - localhost:9121
  - job_name: postgres
    static_configs:
    - targets:
      - localhost:9187
  - job_name: node
    static_configs:
    - targets:
      - localhost:9100
  - job_name: gitlab-workhorse
    static_configs:
    - targets:
      - localhost:9229
  - job_name: gitlab-unicorn
    metrics_path: "/-/metrics"
    static_configs:
    - targets:
      - localhost:8080
  - job_name: gitlab-sidekiq
    static_configs:
    - targets:
      - localhost:8082
  - job_name: gitlab_monitor_database
    metrics_path: "/database"
    static_configs:
    - targets:
      - localhost:9168
  - job_name: gitlab_monitor_sidekiq
    metrics_path: "/sidekiq"
    static_configs:
    - targets:
      - localhost:9168
  - job_name: gitlab_monitor_process
    metrics_path: "/process"
    static_configs:
    - targets:
      - localhost:9168
  - job_name: gitaly
    static_configs:
    - targets:
      - localhost:9236
  - job_name: kubernetes-cadvisor
    scheme: https
    tls_config:
      ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      insecure_skip_verify: true
    bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    kubernetes_sd_configs:
    - role: node
      api_server: https://kubernetes.default.svc:443
      tls_config:
        ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels:
      - __meta_kubernetes_node_name
      regex: "(.+)"
      target_label: __metrics_path__
      replacement: "/api/v1/nodes/${1}/proxy/metrics/cadvisor"
    metric_relabel_configs:
    - source_labels:
      - pod_name
      target_label: environment
      regex: "(.+)-.+-.+"
  - job_name: kubernetes-nodes
    scheme: https
    tls_config:
      ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      insecure_skip_verify: true
    bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    kubernetes_sd_configs:
    - role: node
      api_server: https://kubernetes.default.svc:443
      tls_config:
        ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels:
      - __meta_kubernetes_node_name
      regex: "(.+)"
      target_label: __metrics_path__
      replacement: "/api/v1/nodes/${1}/proxy/metrics"
    metric_relabel_configs:
    - source_labels:
      - pod_name
      target_label: environment
      regex: "(.+)-.+-.+"
  - job_name: kubernetes-pods
    tls_config:
      ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      insecure_skip_verify: true
    bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    kubernetes_sd_configs:
    - role: pod
      api_server: https://kubernetes.default.svc:443
      tls_config:
        ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
    relabel_configs:
    - source_labels:
      - __meta_kubernetes_pod_annotation_prometheus_io_scrape
      action: keep
      regex: 'true'
    - source_labels:
      - __meta_kubernetes_pod_annotation_prometheus_io_path
      action: replace
      target_label: __metrics_path__
      regex: "(.+)"
    - source_labels:
      - __address__
      - __meta_kubernetes_pod_annotation_prometheus_io_port
      action: replace
      regex: "([^:]+)(?::[0-9]+)?;([0-9]+)"
      replacement: "$1:$2"
      target_label: __address__
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels:
      - __meta_kubernetes_namespace
      action: replace
      target_label: kubernetes_namespace
    - source_labels:
      - __meta_kubernetes_pod_name
      action: replace
      target_label: kubernetes_pod_name
PROMYML

describe 'gitlab::prometheus' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(account)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when prometheus is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/prometheus/config') }

    before do
      stub_gitlab_rb(
        prometheus: {
          enable: true
        },
        gitlab_monitor: {
          enable: true
        }
      )
    end

    it_behaves_like 'enabled runit service', 'prometheus', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload prometheus svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/prometheus/)
          expect(content).to match(/prometheus.yml/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(prometheus_yml_output.gsub(/^ {2}/, ''))

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

    it 'should create a gitlab-prometheus user account' do
      expect(chef_run).to create_user('gitlab-prometheus')
    end

    it 'sets a default listen address' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/web.listen-address=localhost:9090/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        prometheus: {
          flags: {
            'storage.local.path' => 'foo'
          },
          listen_address: 'localhost:9898',
          scrape_interval: 11,
          scrape_timeout: 8888,
          enable: true,
          scrape_configs: [
            {
              job_name: 'test',
              static_configs: [
                targets: [
                  'testhost:1234'
                ]
              ]
            }
          ]
        },
        gitaly: {
          prometheus_listen_addr: 'testhost:2345',
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/web.listen-address=localhost:9898/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
    end

    it 'keeps the defaults that the user did not override' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.target-heap-size=47689236/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: gitlab_monitor_database\s+metrics_path: "/database"\s+static_configs:\s+- targets:\s+- localhost:9168})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: gitlab_monitor_sidekiq\s+metrics_path: "/sidekiq"\s+static_configs:\s+- targets:\s+- localhost:9168})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: gitlab_monitor_process\s+metrics_path: "/process"\s+static_configs:\s+- targets:\s+- localhost:9168})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: node\s+static_configs:\s+- targets:\s+- localhost:9100})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: redis\s+static_configs:\s+- targets:\s+- localhost:9121})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: postgres\s+static_configs:\s+- targets:\s+- localhost:9187})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: kubernetes-nodes\s+scheme: https})
    end

    it 'renders prometheus.yml with the non-default value' do
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_timeout: 8888s/)
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_interval: 11/)
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: test\s+static_configs:\s+- targets:\s+- testhost:1234})
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(%r{- job_name: gitaly\s+static_configs:\s+- targets:\s+- testhost:2345})
    end

    context 'when kubernetes monitoring is disabled' do
      before do
        stub_gitlab_rb(
          prometheus: {
            monitor_kubernetes: false
          })
      end

      it 'does not contain kuberentes scrap configuration' do
        expect(chef_run).not_to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
          .with_content(%r{- job_name: kubernetes-nodes\s+scheme: https})
      end
    end
  end

  context 'with default configuration' do
    it 'prometheus and all exporters are enabled' do
      expect(chef_run.node['gitlab']['prometheus-monitoring']['enable']).to be true
      Prometheus.services.each do |service|
        expect(chef_run).to include_recipe("gitlab::#{service}")
      end
    end

    context 'when redis and postgres are disabled' do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false
          },
          redis: {
            enable: false
          }
        )
      end

      context 'and user did not enable the exporter' do
        it 'postgres exporter is disabled' do
          expect(chef_run).not_to include_recipe('gitlab::postgres-exporter')
        end

        it 'redis exporter is disabled' do
          expect(chef_run).not_to include_recipe('gitlab::redis-exporter')
        end
      end

      context 'and user enabled the exporter' do
        before do
          stub_gitlab_rb(
            postgres_exporter: {
              enable: true
            },
            redis_exporter: {
              enable: true
            }
          )
        end

        it 'postgres exporter is enabled' do
          expect(chef_run).to include_recipe('gitlab::postgres-exporter')
        end

        it 'redis exporter is enabled' do
          expect(chef_run).to include_recipe('gitlab::redis-exporter')
        end
      end
    end

    context 'with user provided settings' do
      before do
        stub_gitlab_rb(
          prometheus_monitoring: {
            enable: false
          }
        )
      end

      it 'disables prometheus and all exporters' do
        expect(chef_run.node['gitlab']['prometheus-monitoring']['enable']).to be false
        Prometheus.services.each do |service|
          expect(chef_run).to include_recipe("gitlab::#{service}_disable")
        end
      end
    end
  end
end
