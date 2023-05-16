require 'chef_helper'

RSpec.describe 'praefect' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir)).converge('gitlab::default') }
  let(:prometheus_grpc_latency_buckets) do
    [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when the defaults are used' do
    it_behaves_like 'disabled runit service', 'praefect'
  end

  context 'when praefect is enabled' do
    let(:config_path) { '/var/opt/gitlab/praefect/config.toml' }
    let(:env_dir) { '/opt/gitlab/etc/praefect/env' }
    let(:auth_transitioning) { false }

    before do
      stub_gitlab_rb(praefect: {
                       enable: true,
                       auth_transitioning: auth_transitioning,
                     })
    end

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/praefect').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file and sends hup to service' do
      expect(chef_run).to create_version_file('Create Praefect version file').with(
        version_file_path: '/var/opt/gitlab/praefect/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/praefect --version'
      )

      expect(chef_run.version_file('Create Praefect version file')).to notify('runit_service[praefect]').to(:hup)
    end

    it 'renders the config.toml' do
      rendered = {
        'auth' => { 'transitioning' => false },
        'listen_addr' => 'localhost:2305',
        'logging' => { 'format' => 'json' },
        'prometheus_listen_addr' => 'localhost:9652',
        'failover' => { 'enabled' => true },
      }

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(Tomlrb.parse(content)).to eq(rendered)
      }
      expect(chef_run).not_to render_file(config_path)
      .with_content(%r{\[prometheus\]\s+grpc_latency_buckets =})
    end

    it 'renders the env dir files' do
      expect(chef_run).to render_file(File.join(env_dir, "GITALY_PID_FILE"))
        .with_content('/var/opt/gitlab/praefect/praefect.pid')
      expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
        .with_content('true')
      expect(chef_run).to render_file(File.join(env_dir, "SSL_CERT_DIR"))
        .with_content('/opt/gitlab/embedded/ssl/certs/')
    end

    it 'renders the service run file with wrapper' do
      expect(chef_run).to render_file('/opt/gitlab/sv/praefect/run')
        .with_content('/opt/gitlab/embedded/bin/gitaly-wrapper /opt/gitlab/embedded/bin/praefect')
        .with_content('exec chpst -e /opt/gitlab/etc/praefect/env')
    end

    context 'with defaults overridden with custom configuration' do
      before do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              configuration: {
                listen_addr: 'custom_listen_addr:5432',
                prometheus_listen_addr: 'custom_prometheus_listen_addr:5432',
                logging: {
                  format: 'custom_format',
                  has_no_default: 'should get output'
                },
                auth: {
                  transitioning: true
                },
                failover: {
                  enabled: false
                },
                virtual_storage: [
                  {
                    name: 'default',
                    node: [
                      {
                        storage: 'praefect1',
                        address: 'tcp://node2.internal',
                        token: 'praefect2-token'
                      },
                      {
                        storage: 'praefect2',
                        address: 'tcp://node2.internal',
                        token: 'praefect2-token'
                      }
                    ]
                  },
                  {
                    name: 'virtual-storage-2',
                    node: [
                      {
                        storage: 'praefect3',
                        address: 'tcp://node3.internal',
                        token: 'praefect3-token'
                      },
                      {
                        storage: 'praefect4',
                        address: 'tcp://node4.internal',
                        token: 'praefect4-token'
                      }
                    ]
                  }
                ]
              }
            }
          }
        )
      end

      it 'renders config.toml' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(Tomlrb.parse(content)).to eq(
            {
              'auth' => {
                'transitioning' => true
              },
              'failover' => {
                'enabled' => false
              },
              'listen_addr' => 'custom_listen_addr:5432',
              'logging' => {
                'format' => 'custom_format',
                'has_no_default' => 'should get output'
              },
              'prometheus_listen_addr' => 'custom_prometheus_listen_addr:5432',
              'virtual_storage' => [
                {
                  'name' => 'default',
                  'node' => [
                    {
                      'storage' => 'praefect1',
                      'address' => 'tcp://node2.internal',
                      'token' => 'praefect2-token'
                    },
                    {
                      'storage' => 'praefect2',
                      'address' => 'tcp://node2.internal',
                      'token' => 'praefect2-token'
                    }
                  ]
                },
                {
                  'name' => 'virtual-storage-2',
                  'node' => [
                    {
                      'storage' => 'praefect3',
                      'address' => 'tcp://node3.internal',
                      'token' => 'praefect3-token'
                    },
                    {
                      'storage' => 'praefect4',
                      'address' => 'tcp://node4.internal',
                      'token' => 'praefect4-token'
                    }
                  ]
                }
              ]
            }
          )
        }
      end
    end

    context 'with custom settings' do
      let(:dir) { nil }
      let(:socket_path) { '/var/opt/gitlab/praefect/praefect.socket' }
      let(:auth_token) { 'secrettoken123' }
      let(:auth_transitioning) { false }
      let(:sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project' }
      let(:sentry_environment) { 'production' }
      let(:listen_addr) { 'localhost:4444' }
      let(:tls_listen_addr) { 'localhost:5555' }
      let(:certificate_path) { '/path/to/cert.pem' }
      let(:key_path) { '/path/to/key.pem' }
      let(:prom_addr) { 'localhost:1234' }
      let(:log_level) { 'debug' }
      let(:log_format) { 'text' }
      let(:log_group) { 'fugee' }
      let(:primaries) { %w[praefect1 praefect2] }
      let(:virtual_storage) do
        [
          {
            "default_replication_factor" => 2,
            "name" => "default",
            "node" => [
              {
                "address" => "tcp://node1.internal",
                "storage" => "praefect1",
                "token" => "praefect1-token"
              },
              {
                "address" => "tcp://node2.internal",
                "storage" => "praefect2",
                "token" => "praefect2-token"
              },
              {
                "address" => "tcp://node3.internal",
                "storage" => "praefect3",
                "token" => "praefect3-token"
              },
              {
                "address" => "tcp://node4.internal",
                "storage" => "praefect4",
                "token" => "praefect4-token"
              }
            ]
          }
        ]
      end
      let(:failover_enabled) { true }
      let(:database_host) { 'pg.external' }
      let(:database_port) { 2234 }
      let(:database_user) { 'praefect-pg' }
      let(:database_password) { 'praefect-pg-pass' }
      let(:database_dbname) { 'praefect_production' }
      let(:database_sslmode) { 'require' }
      let(:database_sslcert) { '/path/to/client-cert' }
      let(:database_sslkey) { '/path/to/client-key' }
      let(:database_sslrootcert) { '/path/to/rootcert' }
      let(:database_direct_host) { 'pg.internal' }
      let(:database_direct_port) { 1234 }
      let(:reconciliation_scheduling_interval) { '1m' }
      let(:reconciliation_histogram_buckets) { [1.0, 2.0] }
      let(:user) { 'user123' }
      let(:password) { 'password321' }
      let(:ca_file) { '/path/to/ca_file' }
      let(:ca_path) { '/path/to/ca_path' }
      let(:read_timeout) { 123 }
      let(:graceful_stop_timeout) { '3m' }

      before do
        stub_gitlab_rb(praefect: {
                         enable: true,
                         dir: dir,
                         log_group: log_group,
                         failover_enabled: failover_enabled,
                         # Sanity check that the configuration values get templated out as TOML.
                         configuration: {
                           string_value: 'value',
                           graceful_stop_timeout: graceful_stop_timeout,
                           listen_addr: listen_addr,
                           socket_path: socket_path,
                           auth: {
                             token: auth_token,
                             transitioning: auth_transitioning
                           },
                           logging: {
                             format: log_format,
                             level: log_level
                           },
                           background_verification: {
                             verification_interval: '168h',
                             delete_invalid_records: true,
                           },
                           prometheus: {
                             grpc_latency_buckets: prometheus_grpc_latency_buckets
                           },
                           reconciliation: {
                             scheduling_interval: reconciliation_scheduling_interval,
                             histogram_buckets: reconciliation_histogram_buckets,
                           },
                           sentry: {
                             sentry_dsn: sentry_dsn,
                             sentry_environment: sentry_environment
                           },
                           tls: {
                             certificate_path: certificate_path,
                             key_path: key_path,
                           },
                           tls_listen_addr: tls_listen_addr,
                           virtual_storage: virtual_storage,
                           database: {
                             host: database_host,
                             port: database_port,
                             user: database_user,
                             password: database_password,
                             dbname: database_dbname,
                             sslmode: database_sslmode,
                             sslcert: database_sslcert,
                             sslkey: database_sslkey,
                             sslrootcert: database_sslrootcert,
                             session_pooled: {
                               host: database_direct_host,
                               port: database_direct_port,
                             }
                           },
                           prometheus_listen_addr: prom_addr,
                           subsection: {
                             array_value: [1, 2]
                           },
                         }
                       }
                      )
      end

      it 'renders the config.toml' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(Tomlrb.parse(content)).to eq(
            {
              'auth' => {
                'token' => 'secrettoken123',
                'transitioning' => false,
              },
              'database' => {
                'dbname' => 'praefect_production',
                'host' => 'pg.external',
                'password' => 'praefect-pg-pass',
                'port' => 2234,
                'sslcert' => '/path/to/client-cert',
                'sslkey' => '/path/to/client-key',
                'sslmode' => 'require',
                'sslrootcert' => '/path/to/rootcert',
                'user' => 'praefect-pg',
                'session_pooled' => {
                  'host' => 'pg.internal',
                  'port' => 1234,
                }
              },
              'failover' => {
                'enabled' => true,
              },
              'logging' => {
                'format' => 'text',
                'level' => 'debug'
              },
              'listen_addr' => 'localhost:4444',
              'prometheus' => {
                'grpc_latency_buckets' => [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]
              },
              'reconciliation' => {
                'histogram_buckets' => [1.0, 2.0],
                'scheduling_interval' => '1m'
              },
              'background_verification' => {
                'verification_interval' => '168h',
                'delete_invalid_records' => true
              },
              'sentry' => {
                'sentry_dsn' => 'https://my_key:my_secret@sentry.io/test_project',
                'sentry_environment' => 'production'
              },
              'prometheus_listen_addr' => 'localhost:1234',
              'socket_path' => '/var/opt/gitlab/praefect/praefect.socket',
              'string_value' => 'value',
              'subsection' => {
                'array_value' => [1, 2]
              },
              'tls' => {
                'certificate_path' => '/path/to/cert.pem',
                'key_path' => '/path/to/key.pem'
              },
              'tls_listen_addr' => 'localhost:5555',
              'virtual_storage' => [
                {
                  'name' => 'default',
                  'default_replication_factor' => 2,
                  'node' => [
                    {
                      'address' => 'tcp://node1.internal',
                      'storage' => 'praefect1',
                      'token' => 'praefect1-token'
                    },
                    {
                      'address' => 'tcp://node2.internal',
                      'storage' => 'praefect2',
                      'token' => 'praefect2-token'
                    },
                    {
                      'address' => 'tcp://node3.internal',
                      'storage' => 'praefect3',
                      'token' => 'praefect3-token'
                    },
                    {
                      'address' => 'tcp://node4.internal',
                      'storage' => 'praefect4',
                      'token' => 'praefect4-token'
                    }
                  ]
                }
              ],
              'graceful_stop_timeout' => graceful_stop_timeout
            }
          )
        }
      end

      it 'renders the env dir files correctly' do
        expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
          .with_content('false')
      end
    end

    describe 'database migrations' do
      it 'runs the migrations' do
        expect(chef_run).to run_bash('migrate praefect database')
      end

      context 'with auto_migrate off' do
        before { stub_gitlab_rb(praefect: { auto_migrate: false }) }

        it 'skips running the migrations' do
          expect(chef_run).not_to run_bash('migrate praefect database')
        end
      end
    end

    context 'log directory and runit group' do
      context 'default values' do
        before do
          stub_gitlab_rb(praefect: { enable: true })
        end
        it_behaves_like 'enabled logged service', 'praefect', true, { log_directory_owner: 'git' }
      end

      context 'custom values' do
        before do
          stub_gitlab_rb(
            praefect: {
              enable: true,
              log_group: 'fugee'
            }
          )
        end
        it_behaves_like 'enabled logged service', 'praefect', true, { log_directory_owner: 'git', log_group: 'fugee' }
      end
    end

    include_examples "consul service discovery", "praefect", "praefect"
  end
end
