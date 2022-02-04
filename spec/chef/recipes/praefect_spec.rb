require 'chef_helper'
RSpec.describe 'praefect' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir)).converge('gitlab::default') }
  let(:prometheus_grpc_latency_buckets) do
    '[0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]'
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
        'auth' => { 'token' => '', 'transitioning' => false },
        'listen_addr' => 'localhost:2305',
        'logging' => { 'format' => 'json' },
        'prometheus_listen_addr' => 'localhost:9652',
        'prometheus_exclude_database_from_default_metrics' => true,
        'sentry' => {},
        'database' => {
          'session_pooled' => {},
        },
        'reconciliation' => {},
        'failover' => { 'enabled' => true }
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
      let(:separate_database_metrics) { false }
      let(:log_level) { 'debug' }
      let(:log_format) { 'text' }
      let(:primaries) { %w[praefect1 praefect2] }
      let(:virtual_storages) do
        {
          'default' => {
            'default_replication_factor' => 2,
            'nodes' => {
              'praefect1' => { address: 'tcp://node1.internal', token: "praefect1-token" },
              'praefect2' => { address: 'tcp://node2.internal', token: "praefect2-token" },
              'praefect3' => { address: 'tcp://node3.internal', token: "praefect3-token" },
              'praefect4' => { address: 'tcp://node4.internal', token: "praefect4-token" }
            },
            'praefect5' => { address: 'tcp://node5.internal', token: "praefect5-token" }
          }
        }
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
      let(:database_sslrootcert) { '/path/to/rootcert' }
      let(:database_direct_host) { 'pg.internal' }
      let(:database_direct_port) { 1234 }
      let(:reconciliation_scheduling_interval) { '1m' }
      let(:reconciliation_histogram_buckets) { '[1.0, 2.0]' }

      before do
        stub_gitlab_rb(praefect: {
                         enable: true,
                         dir: dir,
                         socket_path: socket_path,
                         auth_token: auth_token,
                         auth_transitioning: auth_transitioning,
                         sentry_dsn: sentry_dsn,
                         sentry_environment: sentry_environment,
                         listen_addr: listen_addr,
                         tls_listen_addr: tls_listen_addr,
                         certificate_path: certificate_path,
                         key_path: key_path,
                         prometheus_listen_addr: prom_addr,
                         prometheus_grpc_latency_buckets: prometheus_grpc_latency_buckets,
                         separate_database_metrics: separate_database_metrics,
                         logging_level: log_level,
                         logging_format: log_format,
                         failover_enabled: failover_enabled,
                         virtual_storages: virtual_storages,
                         database_host: database_host,
                         database_port: database_port,
                         database_user: database_user,
                         database_password: database_password,
                         database_dbname: database_dbname,
                         database_sslmode: database_sslmode,
                         database_sslcert: database_sslcert,
                         database_sslkey: database_sslkey,
                         database_sslrootcert: database_sslrootcert,
                         database_direct_host: database_direct_host,
                         database_direct_port: database_direct_port,
                         reconciliation_scheduling_interval: reconciliation_scheduling_interval,
                         reconciliation_histogram_buckets: reconciliation_histogram_buckets,
                       })
      end

      it 'renders the config.toml' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(Tomlrb.parse(content)).to eq(
            {
              'auth' => {
                'token' => 'secrettoken123',
                'transitioning' => false
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
                'enabled' => true
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
              'sentry' => {
                'sentry_dsn' => 'https://my_key:my_secret@sentry.io/test_project',
                'sentry_environment' => 'production'
              },
              'prometheus_listen_addr' => 'localhost:1234',
              'prometheus_exclude_database_from_default_metrics' => false,
              'socket_path' => '/var/opt/gitlab/praefect/praefect.socket',
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
                    },
                    {
                      'address' => 'tcp://node5.internal',
                      'storage' => 'praefect5',
                      'token' => 'praefect5-token'
                    }
                  ]
                }
              ]
            }
          )
        }
      end

      it 'renders the env dir files correctly' do
        expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
          .with_content('false')
      end

      context 'with virtual_storages as an array' do
        let(:virtual_storages) { [{ name: 'default', 'nodes' => [{ storage: 'praefect1', address: 'tcp://node1.internal', token: "praefect1-token" }] }] }

        it 'raises an error' do
          expect { chef_run }.to raise_error("Praefect virtual_storages must be a hash")
        end
      end

      context 'with duplicate virtual storage node configured via fallback' do
        let(:virtual_storages) { { 'default' => { 'node-1' => {}, 'nodes' => { 'node-1' => {} } } } }

        it 'raises an error' do
          allow(LoggingHelper).to receive(:deprecation)
          expect(LoggingHelper).to receive(:deprecation).with(
            <<~EOS
              Configuring the Gitaly nodes directly in the virtual storage's root configuration object has
              been deprecated in GitLab 13.12 and will no longer be supported in GitLab 15.0. Move the Gitaly
              nodes under the 'nodes' key as described in step 6 of https://docs.gitlab.com/ee/administration/gitaly/praefect.html#praefect.
            EOS
          )

          expect { chef_run }.to raise_error("Virtual storage 'default' contains duplicate configuration for node 'node-1'")
        end
      end

      context 'with nodes within virtual_storages as an array' do
        let(:virtual_storages) { { 'default' => [{ storage: 'praefect1', address: 'tcp://node1.internal', token: "praefect1-token" }] } }

        it 'raises an error' do
          expect { chef_run }.to raise_error("nodes of a Praefect virtual_storage must be a hash")
        end
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

    include_examples "consul service discovery", "praefect", "praefect"
  end
end
