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
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('gitlab-kas').and_return(true)
      expect(chef_run).to create_version_file('Create version file for Gitlab KAS').with(
        version_file_path: '/var/opt/gitlab/gitlab-kas/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/gitlab-kas --version'
      )

      expect(chef_run.version_file('Create version file for Gitlab KAS')).to notify('runit_service[gitlab-kas]').to(:restart)
    end

    it 'creates a default VERSION file and does not restart the service if stopped' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('gitlab-kas').and_return(false)
      expect(chef_run).to create_version_file('Create version file for Gitlab KAS').with(
        version_file_path: '/var/opt/gitlab/gitlab-kas/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/gitlab-kas --version'
      )

      expect(chef_run.version_file('Create version file for Gitlab KAS')).to_not notify('runit_service[gitlab-kas]').to(:restart)
    end

    it 'correctly renders the KAS service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/run").with_content(%r{--configuration-file /var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml})
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
              url_path_prefix: '/',
              websocket_token_secret_file: "/var/opt/gitlab/gitlab-kas/websocket_token_secret_file"
            }
          ),
          observability: {
            listen: {
              address: 'localhost:8151',
              network: 'tcp'
            },
            logging: {
              level: 'info',
              grpc_level: 'error'
            },
            usage_reporting_period: '60s'
          },
          private_api: {
            listen: {
              address: "localhost:8155",
              authentication_secret_file: "/var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file",
              network: "tcp"
            },
          },
          gitlab: hash_including(
            external_url: 'https://gitlab.example.com'
          )
        )
      )
    end

    it 'correctly renders the KAS authentication secret files' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content { |content| Base64.strict_decode64(content).size == 32 }
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file").with_content { |content| Base64.strict_decode64(content).size == 32 }
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/websocket_token_secret_file").with_content { |content| Base64.strict_decode64(content).size == 72 }
    end

    it 'sets SSL_CERT_DIR' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-kas/env/SSL_CERT_DIR').with_content('/opt/gitlab/embedded/ssl/certs/')
    end

    it 'sets GODEBUG' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-kas/env/GODEBUG').with_content('tlsmlkem=0')
    end
  end

  context 'with user settings' do
    let(:api_secret_key) { Base64.strict_encode64('1' * 32) }
    let(:private_api_secret_key) { Base64.strict_encode64('2' * 32) }
    let(:websocket_token_secret_key) { Base64.strict_encode64('3' * 72) }

    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        gitlab_kas: {
          api_secret_key: api_secret_key,
          private_api_secret_key: private_api_secret_key,
          websocket_token_secret_key: websocket_token_secret_key,
          listen_address: 'localhost:5006',
          listen_websocket: false,
          observability_listen_address: '0.0.0.0:8151',
          metrics_usage_reporting_period: '120',
          sentry_dsn: 'https://my_key:my_secret@sentry.io/test_project',
          sentry_environment: 'production',
          log_level: 'debug',
          grpc_log_level: 'debug',
          env: {
            'OWN_PRIVATE_API_HOST' => 'fake-host.example.com'
          }
        }
      )
    end

    it 'correctly renders the KAS service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-kas/run").with_content(%r{--configuration-file /var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml})
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
            listen: {
              address: '0.0.0.0:8151',
              network: 'tcp'
            },
            logging: {
              level: 'debug',
              grpc_level: 'debug'
            },
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
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/websocket_token_secret_file").with_content(websocket_token_secret_key)
    end

    it 'sets OWN_PRIVATE_API_HOST' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-kas/env/OWN_PRIVATE_API_HOST').with_content('fake-host.example.com')
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

      it 'has external URL with scheme `ws` instead of `wss`' do
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

    context 'with GitLab on a relative URL' do
      before do
        stub_gitlab_rb(
          external_url: 'https://example.com/gitlab'
        )
      end

      it 'renders gitlab_kas enabled with relative URLs in config/gitlab.yml' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://example.com/gitlab/-/kubernetes-agent/',
          internal_url: 'grpc://localhost:8153',
          external_k8s_proxy_url: 'https://example.com/gitlab/-/kubernetes-agent/k8s-proxy/'
        )
      end

      it 'renders KAS config gitlab external URL correctly' do
        expect(gitlab_kas_config_yml).to(
          include(
            gitlab: hash_including(
              external_url: 'https://example.com'
            )
          )
        )
      end
    end

    context 'with kas url using own sub-domain' do
      it "allows ws/wss scheme if gitlab_kas['listen_websocket']=true" do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas_external_url: 'wss://kas.gitlab.example.com/',
          gitlab_kas: { listen_websocket: true }
        )

        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://kas.gitlab.example.com/',
          external_k8s_proxy_url: 'https://kas.gitlab.example.com/k8s-proxy/'
        )
      end

      it "raises an error if gitlab_kas['listen_websocket']=false" do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas_external_url: 'wss://kas.gitlab.example.com',
          gitlab_kas: { listen_websocket: false }
        )

        expect { gitlab_yml }.to raise_error(
          RuntimeError,
          "gitlab_kas['listen_websocket'] must be set to `true`"
        )
      end

      it "does not allow grpc/grpcs" do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas_external_url: 'grpcs://kas.gitlab.example.com/',
          gitlab_kas: { listen_websocket: false }
        )

        expect { gitlab_yml }.to raise_error(
          RuntimeError,
          "gitlab_kas_external_url scheme must be 'ws' or 'wss'"
        )
      end

      it "does not allow http/https" do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas_external_url: 'https://kas.gitlab.example.com/',
          gitlab_kas: { listen_websocket: false }
        )

        expect { gitlab_yml }.to raise_error(
          RuntimeError,
          "gitlab_kas_external_url scheme must be 'ws' or 'wss'"
        )
      end

      it 'renders KAS config gitlab external URL correctly' do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas_external_url: 'wss://kas.gitlab.example.com/',
          gitlab_kas: { listen_websocket: true }
        )

        expect(gitlab_kas_config_yml).to(
          include(
            gitlab: hash_including(
              external_url: 'https://gitlab.example.com'
            )
          )
        )
      end
    end
  end

  describe 'redis config' do
    context 'when same as gitlab_rails' do
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
              redis_tls_client_cert_file: '/etc/gitlab/self_signed.crt',
              redis_tls_client_key_file: '/etc/gitlab/self_signed.key'
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
                  'enabled' => true,
                  'ca_certificate_file' => '/opt/gitlab/embedded/ssl/certs/cacert.pem',
                  'certificate_file' => '/etc/gitlab/self_signed.crt',
                  'key_file' => '/etc/gitlab/self_signed.key',
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
        let(:sentinel_params) do
          {
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
          }
        end

        before do
          stub_gitlab_rb(sentinel_params)
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

        context 'when there is a Sentinel password' do
          before do
            sentinel_params[:gitlab_rails]['redis_sentinels_password'] = 'some pass'

            stub_gitlab_rb(sentinel_params)
          end

          it 'writes sentinel_password_file in to the kas config' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content { |content|
              kas_redis_cfg = YAML.safe_load(content)['redis']

              expect(kas_redis_cfg).to(
                include(
                  'sentinel' => {
                    'master_name' => 'example-redis',
                    'addresses' => [
                      'a:1',
                      'b:2',
                      'c:6379'
                    ],
                    'sentinel_password_file' => '/var/opt/gitlab/gitlab-kas/redis_sentinels_password_file'
                  }
                )
              )
            }
          end

          it 'renders the password file' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/redis_sentinels_password_file').with_content('some pass')
          end
        end
      end
    end

    context 'when different from gitlab_rails' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: '1.2.3.4',
            redis_port: '6379',
            redis_password: 'rails_redis_password'
          },
          gitlab_kas: {
            redis_host: '4.5.6.7',
            redis_port: '6389',
            redis_password: 'kas_redis_password'
          }
        )
      end

      it 'renders KAS config files with KAS specific Redis values' do
        expect(gitlab_kas_config_yml[:redis]).to eq(
          network: "tcp",
          password_file: "/var/opt/gitlab/gitlab-kas/redis_password_file",
          server: {
            address: "4.5.6.7:6389"
          },
          tls: {
            enabled: false
          }
        )
      end

      it 'renders the password file with KAS specific value' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/redis_password_file').with_content('kas_redis_password')
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

    context 'log directory and runit group' do
      context 'default values' do
        it_behaves_like 'enabled logged service', 'gitlab-kas', true, { log_directory_owner: 'git' }
      end

      context 'custom values' do
        before do
          stub_gitlab_rb(
            gitlab_kas: {
              log_group: 'fugee'
            }
          )
        end
        it_behaves_like 'configured logrotate service', 'gitlab-kas', 'git', 'fugee'
        it_behaves_like 'enabled logged service', 'gitlab-kas', true, { log_directory_owner: 'git', log_group: 'fugee' }
      end
    end
  end

  describe 'extra config command' do
    context 'by default' do
      it 'is not renderered in the config file' do
        expect(gitlab_kas_config_yml[:config]).to be_nil
      end
    end

    context 'when specified' do
      before do
        stub_gitlab_rb(
          gitlab_kas: {
            extra_config_command: "/opt/kas-redis-config.sh"
          }
        )
      end

      it 'is rendered in the config file' do
        expect(gitlab_kas_config_yml[:config]).to eq(command: "/opt/kas-redis-config.sh")
      end
    end
  end

  describe 'chef_run.file calls' do
    def files
      @files ||= %w(
        /var/opt/gitlab/gitlab-kas/authentication_secret_file
        /var/opt/gitlab/gitlab-kas/private_api_authentication_secret_file
        /var/opt/gitlab/gitlab-kas/websocket_token_secret_file
        /var/opt/gitlab/gitlab-kas/redis_password_file
        /var/opt/gitlab/gitlab-kas/redis_sentinels_password_file
      )
    end

    before do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
    end

    context "when omnibus_helper.should_notify?('gitlab-kas') returns true" do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('gitlab-kas').and_return(true)
      end

      it 'chef_run.file calls notify gitlab-kas to restart' do
        files.each do |file|
          expect(chef_run.file(file)).to notify('runit_service[gitlab-kas]').to(:restart)
        end
      end
    end

    context "when omnibus_helper.should_notify?('gitlab-kas') returns false" do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('gitlab-kas').and_return(false)
      end

      it 'chef_run.file calls do not notify gitlab-kas to restart' do
        files.each do |file|
          expect(chef_run.file(file)).to_not notify('runit_service[gitlab-kas]').to(:restart)
        end
      end
    end
  end

  def chef_run_load_yaml_template(chef_run, path)
    template = chef_run.template(path)
    file_content = ChefSpec::Renderer.new(chef_run, template).content
    YAML.safe_load(file_content, aliases: true, symbolize_names: true)
  end
end
