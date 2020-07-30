require 'chef_helper'
describe 'praefect' do
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
        'sentry' => {},
        'database' => {},
        'failover' => { 'enabled' => false,
                        'election_strategy' => 'sql' }
      }

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(Tomlrb.parse(content)).to eq(rendered)
      }
      expect(chef_run).not_to render_file(config_path)
      .with_content(%r{\[prometheus\]\s+grpc_latency_buckets =})
      expect(chef_run).to render_file(config_path)
      .with_content(%r{\[failover\]\s+enabled = false\s+election_strategy = 'sql'})
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
      let(:primaries) { %w[praefect1 praefect2] }
      let(:virtual_storages) do
        {
          'default' => {
            'praefect1' => { address: 'tcp://node1.internal', primary: true, token: "praefect1-token" },
            'praefect2' => { address: 'tcp://node2.internal', primary: 'true', token: "praefect2-token" },
            'praefect3' => { address: 'tcp://node3.internal', primary: false, token: "praefect3-token" },
            'praefect4' => { address: 'tcp://node4.internal', primary: 'false', token: "praefect4-token" },
            'praefect5' => { address: 'tcp://node5.internal', token: "praefect5-token" }
          }
        }
      end
      let(:failover_enabled) { true }
      let(:failover_election_strategy) { 'local' }
      let(:database_host) { 'pg.internal' }
      let(:database_port) { 1234 }
      let(:database_user) { 'praefect-pg' }
      let(:database_password) { 'praefect-pg-pass' }
      let(:database_dbname) { 'praefect_production' }
      let(:database_sslmode) { 'require' }
      let(:database_sslcert) { '/path/to/client-cert' }
      let(:database_sslkey) { '/path/to/client-key' }
      let(:database_sslrootcert) { '/path/to/rootcert' }

      before do
        stub_gitlab_rb(praefect: {
                         enable: true,
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
                         logging_level: log_level,
                         logging_format: log_format,
                         failover_enabled: failover_enabled,
                         failover_election_strategy: failover_election_strategy,
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
                       })
      end

      it 'renders the config.toml' do
        expect(chef_run).to render_file(config_path)
          .with_content("listen_addr = '#{listen_addr}'")
        expect(chef_run).to render_file(config_path)
          .with_content(%r{^tls_listen_addr = '#{tls_listen_addr}'\n\[tls\]\ncertificate_path = '#{certificate_path}'\nkey_path = '#{key_path}'\n})
        expect(chef_run).to render_file(config_path)
          .with_content("socket_path = '#{socket_path}'")
        expect(chef_run).to render_file(config_path)
          .with_content("prometheus_listen_addr = '#{prom_addr}'")
        expect(chef_run).to render_file(config_path)
          .with_content("level = '#{log_level}'")
        expect(chef_run).to render_file(config_path)
          .with_content("format = '#{log_format}'")
        expect(chef_run).to render_file(config_path)
          .with_content("sentry_dsn = '#{sentry_dsn}'")
        expect(chef_run).to render_file(config_path)
          .with_content("sentry_environment = '#{sentry_environment}'")
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[failover\]\s+enabled = true\s+election_strategy = 'local'})
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[prometheus\]\s+grpc_latency_buckets = #{Regexp.escape(prometheus_grpc_latency_buckets)}})

        expect(chef_run).to render_file(config_path)
          .with_content(%r{^\[auth\]\ntoken = '#{auth_token}'\ntransitioning = #{auth_transitioning}\n})

        virtual_storages.each do |name, nodes|
          expect(chef_run).to render_file(config_path).with_content(%r{^\[\[virtual_storage\]\]\nname = '#{name}'\n})
          nodes.each do |storage, node|
            expect_primary = primaries.include?(storage)

            expect(chef_run).to render_file(config_path)
              .with_content(%r{^\[\[virtual_storage.node\]\]\nstorage = '#{storage}'\naddress = '#{node[:address]}'\ntoken = '#{node[:token]}'\nprimary = #{expect_primary}\n})
          end
        end

        database_section = Regexp.new([
          %r{\[database\]},
          %r{host = '#{database_host}'},
          %r{port = #{database_port}},
          %r{user = '#{database_user}'},
          %r{password = '#{database_password}'},
          %r{dbname = '#{database_dbname}'},
          %r{sslmode = '#{database_sslmode}'},
          %r{sslcert = '#{database_sslcert}'},
          %r{sslkey = '#{database_sslkey}'},
          %r{sslrootcert = '#{database_sslrootcert}'},
        ].map(&:to_s).join('\n'))

        expect(chef_run).to render_file(config_path).with_content(database_section)
      end

      it 'renders the env dir files correctly' do
        expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
          .with_content('false')
      end

      context 'with virtual_storages as an array' do
        let(:virtual_storages) { [{ name: 'default', 'nodes' => [{ storage: 'praefect1', address: 'tcp://node1.internal', primary: true, token: "praefect1-token" }] }] }

        it 'raises an error' do
          expect { chef_run }.to raise_error("Praefect virtual_storages must be a hash")
        end
      end

      context 'with nodes within virtual_storages as an array' do
        let(:virtual_storages) { { 'default' => [{ storage: 'praefect1', address: 'tcp://node1.internal', primary: true, token: "praefect1-token" }] } }

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
  end
end
