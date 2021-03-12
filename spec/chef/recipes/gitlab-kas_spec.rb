require 'chef_helper'

RSpec.describe 'gitlab-kas' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir templatesymlink)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        gitlab_kas: {
          enable: true
        }
      )
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
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^    address: localhost:8150})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^    websocket: true})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  usage_reporting_period: 60s})
    end

    it 'correctly renders the KAS authentication secret file' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content { |content| Base64.strict_decode64(content).size == 32 }
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        gitlab_kas: {
          api_secret_key: 'QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE=',
          enable: true,
          listen_address: 'localhost:5006',
          listen_websocket: false,
          metrics_usage_reporting_period: '120'
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
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^    address: localhost:5006})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^    websocket: false})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  usage_reporting_period: 120s})
    end

    it 'correctly renders the KAS authentication secret file' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content('QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE=')
    end
  end

  describe 'gitlab.yml configuration' do
    let(:gitlab_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }
    let(:gitlab_yml_file_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml_template).content }
    let(:gitlab_yml) { YAML.safe_load(gitlab_yml_file_content, [], [], true, symbolize_names: true) }

    context 'with defaults' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true
          }
        )
      end

      it 'renders gitlab_kas enabled with default URLs in config/gitlab.yml' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://gitlab.example.com/-/kubernetes-agent',
          internal_url: 'grpc://localhost:8153'
        )
      end
    end

    context 'when not https' do
      before do
        stub_gitlab_rb(
          external_url: 'http://gitlab.example.com',
          gitlab_kas: {
            enable: true
          }
        )
      end

      it 'has exernal URL with scheme `ws` instead of `wss`' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          external_url: 'ws://gitlab.example.com/-/kubernetes-agent'
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

      it 'derives the external URL from the top level external URL, and the internal URL from the listen address' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          enabled: true,
          external_url: 'wss://gitlab.example.com/-/kubernetes-agent',
          internal_url: 'grpc://custom-api-address:9999'
        )
      end
    end

    context 'with explicitly configured URLs' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: {
            gitlab_kas_external_url: 'wss://kas.example.com',
            gitlab_kas_internal_url: 'grpc://kas.internal'
          },
          gitlab_kas: {
            enable: true
          }
        )
      end

      it 'uses the explicitly configured URL' do
        expect(gitlab_yml[:production][:gitlab_kas]).to include(
          external_url: 'wss://kas.example.com',
          internal_url: 'grpc://kas.internal'
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
          gitlab_kas: {
            enable: true
          },
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

    context 'without sentinel' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true
          },
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

    context 'with sentinel' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: {
            enable: true
          },
          gitlab_rails: {
            redis_sentinels: [
              { host: 'a', port: 1 },
              { host: 'b', port: 2 }
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
                  'b:2'
                ]
              }
            )
          )
          expect(kas_redis_cfg).not_to(include('server'))
        }
      end
    end
  end
end
