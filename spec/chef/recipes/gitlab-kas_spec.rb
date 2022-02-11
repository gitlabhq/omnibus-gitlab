require 'chef_helper'

RSpec.describe 'gitlab-kas' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir templatesymlink)).converge('gitlab::default') }
  let(:gitlab_kas_config_yml) { chef_run_load_yaml_template(chef_run, '/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when application_role is configured' do
    before do
      stub_gitlab_rb(roles: %w(application_role))
    end

    it 'should be enabled' do
      expect(chef_run).to include_recipe('gitlab-kas::enable')
    end
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(external_url: 'https://gitlab.example.com')
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Gitlab KAS').with(
        version_file_path: '/var/opt/gitlab/gitlab-kas/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/gitlab-kas --version'
      )

      expect(chef_run.version_file('Create version file for Gitlab KAS')).to notify('runit_service[gitlab-kas]').to(:restart)
    end

    it 'correctly renders the KAS service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/run").with_content(%r{--configuration-file /var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml})
    end

    it 'correctly renders the KAS log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/log/run").with_content(%r{exec svlogd -tt /var/log/gitlab/gitlab-kas})
    end

    it 'correctly renders the KAS config file' do
      expect(gitlab_kas_config_yml).to(
        include(
          agent: hash_including(
            listen: {
              network: 'tcp',
              address: 'localhost:8150',
              websocket: true,
            },
            kubernetes_api: {
              listen: {
                address: 'localhost:8154',
              },
              url_path_prefix: '/'
            }
          ),
          observability: {
            usage_reporting_period: '60s'
          },
          private_api: {
            listen: {
              address: "localhost:8155",
              authentication_secret_file: "/var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file",
              network: "tcp"
            },
          }
        )
      )
    end

    it 'correctly renders the KAS authentication secret files' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content { |content| Base64.strict_decode64(content).size == 32 }
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file").with_content { |content| Base64.strict_decode64(content).size == 32 }
    end

    it 'sets OWN_PRIVATE_API_URL and SSL_CERT_DIR' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-kas/env/OWN_PRIVATE_API_URL').with_content('grpc://localhost:8155')
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-kas/env/SSL_CERT_DIR').with_content('/opt/gitlab/embedded/ssl/certs/')
    end
  end

  context 'with user settings' do
    let(:api_secret_key) { Base64.strict_encode64('1' * 32) }
    let(:private_api_secret_key) { Base64.strict_encode64('2' * 32) }

    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        gitlab_kas: {
          api_secret_key: api_secret_key,
          private_api_secret_key: private_api_secret_key,
          listen_address: 'localhost:5006',
          listen_websocket: false,
          metrics_usage_reporting_period: '120',
          sentry_dsn: 'https://my_key:my_secret@sentry.io/test_project',
          sentry_environment: 'production'
        }
      )
    end

    it 'correctly renders the KAS service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/run").with_content(%r{--configuration-file /var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml})
    end

    it 'correctly renders the KAS log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/log/run").with_content(%r{exec svlogd -tt /var/log/gitlab/gitlab-kas})
    end

    it 'correctly renders the KAS config file' do
      expect(gitlab_kas_config_yml).to(
        include(
          agent: hash_including(
            listen: {
              network: 'tcp',
              address: 'localhost:5006',
              websocket: false
            }
          ),
          observability: {
            usage_reporting_period: '120s',
            sentry: {
              dsn: 'https://my_key:my_secret@sentry.io/test_project',
              environment: 'production'
            }
          }
        )
      )
    end

    it 'correctly renders the KAS authentication secret files' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content(api_secret_key)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file").with_content(private_api_secret_key)
    end
  end

  describe 'gitlab.yml configuration' do
    let(:gitlab_yml) { chef_run_load_yaml_template(chef_run, '/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }

    context 'with defaults' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com'
        )
      end

      it 'renders gitlab_kas enabled with default URLs in config/gitlab.yml' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://gitlab.example.com/-/kubernetes-agent/',
          internal_url: 'grpc://localhost:8153',
          external_k8s_proxy_url: 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
        )
      end
    end

    context 'when not https' do
      before do
        stub_gitlab_rb(
          external_url: 'http://gitlab.example.com'
        )
      end

      it 'has exernal URL with scheme `ws` instead of `wss`' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          external_url: 'ws://gitlab.example.com/-/kubernetes-agent/'
        )
      end
    end

    context 'with custom listen addresses' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true,
            listen_address: 'custom-address:1234',
            internal_api_listen_address: 'custom-api-address:9999'
          }
        )
      end

      it 'derives the external URLs from the top level external URL, and the internal URL from the listen address' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://gitlab.example.com/-/kubernetes-agent/',
          internal_url: 'grpc://custom-api-address:9999',
          external_k8s_proxy_url: 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
        )
      end
    end

    context 'with explicitly configured URLs' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: {
            gitlab_kas_external_url: 'wss://kas.example.com',
            gitlab_kas_internal_url: 'grpc://kas.internal',
            gitlab_kas_external_k8s_proxy_url: 'https://kas.example.com/k8s-proxy'
          }
        )
      end

      it 'uses the explicitly configured URL' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          external_url: 'wss://kas.example.com',
          internal_url: 'grpc://kas.internal',
          external_k8s_proxy_url: 'https://kas.example.com/k8s-proxy'
        )
      end
    end
  end

  describe 'logrotate settings' do
    context 'default values' do
      it_behaves_like 'configured logrotate service', 'gitlab-kas', 'git', 'git'
    end

    context 'specified username and group' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'configured logrotate service', 'gitlab-kas', 'foo', 'bar'
    end
  end

  describe 'redis config' do
    context 'when there is a password' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: { enable: true },
          gitlab_rails: { redis_password: 'the-password' }
        )
      end

      it 'writes password_file into the kas config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_redis_cfg = YAML.safe_load(content)['redis']
          expect(kas_redis_cfg).to(
            include(
              'password_file' => '/var/opt/gitlab/gitlab-kas/redis_password_file'
            )
          )
        }
      end
      it 'renders the password file' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/redis_password_file').with_content('the-password')
      end
    end

    context 'when there is no password' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: { enable: true }
        )
      end

      it 'does not write password_file into the config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_cfg = YAML.safe_load(content)
          expect(kas_cfg['redis']).not_to include('password_file')
        }
      end

      it 'renders no password file' do
        expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-kas/redis_password_file")
      end
    end

    context 'without sentinel host only' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true
          },
          gitlab_rails: {
            redis_host: 'the-host'
          }
        )
      end

      it 'renders a single server configuration in to the kas config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_redis_cfg = YAML.safe_load(content)['redis']
          expect(kas_redis_cfg).to(
            include(
              'network' => 'tcp',
              'server' => {
                'address' => 'the-host:6379'
              }
            )
          )
          expect(kas_redis_cfg).not_to(include('sentinel'))
        }
      end
    end

    context 'without sentinel host and port' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: {
            redis_host: 'the-host',
            redis_port: 12345,
          }
        )
      end

      it 'renders a single server configuration in to the kas config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_redis_cfg = YAML.safe_load(content)['redis']
          expect(kas_redis_cfg).to(
            include(
              'network' => 'tcp',
              'server' => {
                'address' => 'the-host:12345'
              }
            )
          )
          expect(kas_redis_cfg).not_to(include('sentinel'))
        }
      end
    end

    context 'without sentinel but with tls enabled' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: {
            redis_host: 'the-host',
            redis_port: 12345,
            redis_ssl: true,
          }
        )
      end

      it 'renders a configuration with tls enabled in to the kas config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_redis_cfg = YAML.safe_load(content)['redis']
          expect(kas_redis_cfg).to(
            include(
              'network' => 'tcp',
              'tls' => {
                'enabled' => true
              },
              'server' => {
                'address' => 'the-host:12345'
              }
            )
          )
        }
      end
    end

    context 'with sentinel' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: {
            redis_sentinels: [
              { host: 'a', port: 1 },
              { host: 'b', port: 2 },
              { host: 'c' }
            ]
          },
          redis: {
            master_name: 'example-redis'
          }
        )
      end

      it 'renders a single server configuration in to the kas config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
          kas_redis_cfg = YAML.safe_load(content)['redis']
          expect(kas_redis_cfg).to(
            include(
              'network' => 'tcp',
              'sentinel' => {
                'master_name' => 'example-redis',
                'addresses' => [
                  'a:1',
                  'b:2',
                  'c:6379'
                ]
              }
            )
          )
          expect(kas_redis_cfg).not_to(include('server'))
        }
      end
    end
  end

  describe 'TLS listen config' do
    context 'when all certificates and keys are defined' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true,
            listen_websocket: false,
            certificate_file: '/path/to/cert.pem',
            key_file: '/path/to/key.pem',
            internal_api_certificate_file: '/path/to/internal-api-cert.pem',
            internal_api_key_file: '/path/to/internal-api-key.pem',
            kubernetes_api_certificate_file: '/path/to/kubernetes-api-cert.pem',
            kubernetes_api_key_file: '/path/to/kubernetes-api-key.pem',
            private_api_certificate_file: '/path/to/private-api-cert.pem',
            private_api_key_file: '/path/to/private-api-key.pem'
          }
        )
      end

      it 'correctly renders the KAS config file' do
        expect(gitlab_kas_config_yml).to(
          include(
            agent: hash_including(
              listen: hash_including(
                certificate_file: '/path/to/cert.pem',
                key_file: '/path/to/key.pem'
              ),
              kubernetes_api: hash_including(
                listen: hash_including(
                  certificate_file: '/path/to/kubernetes-api-cert.pem',
                  key_file: '/path/to/kubernetes-api-key.pem'
                )
              )
            ),
            api: {
              listen: hash_including(
                certificate_file: '/path/to/internal-api-cert.pem',
                key_file: '/path/to/internal-api-key.pem'
              ),
            },
            private_api: {
              listen: hash_including(
                certificate_file: '/path/to/private-api-cert.pem',
                key_file: '/path/to/private-api-key.pem'
              )
            }
          )
        )
      end
    end

    context 'when certificate/key bundles are not correctly defined' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true,
            certificate_file: '/path/to/file.pem',
            internal_api_certificate_file: '/path/to/file.pem',
            kubernetes_api_key_file: '/path/to/file.pem',
            private_api_key_file: '/path/to/file.pem'
          }
        )
      end

      it 'renders no certificate or key configuration' do
        expect(gitlab_kas_config_yml).not_to(include('/path/to/file.pem'))
      end
    end

    context 'when the certificate/key bundle is defined and websocket tunneling is enabled' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true,
            listen_websocket: true,
            certificate_file: '/path/to/cert.pem',
            key_file: '/path/to/key.pem',
          }
        )
      end

      it 'logs a warning' do
        expect(chef_run).to run_ruby_block('websocket TLS termination')
      end
    end
  end

  def chef_run_load_yaml_template(chef_run, path)
    template = chef_run.template(path)
    file_content = ChefSpec::Renderer.new(chef_run, template).content
    YAML.safe_load(file_content, [], [], true, symbolize_names: true)
  end
end
