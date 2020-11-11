require 'chef_helper'

RSpec.describe 'gitlab-kas' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir)).converge('gitlab::default') }

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
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  address: localhost:8150})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  websocket: true})
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
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  address: localhost:5006})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  websocket: false})
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-kas/gitlab-kas-config.yml').with_content(%r{^  usage_reporting_period: 120s})
    end

    it 'correctly renders the KAS authentication secret file' do
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-kas/authentication_secret_file").with_content('QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE=')
    end
  end

  describe 'logrotate settings' do
    context 'default values' do
      it_behaves_like 'configured logrotate service', 'gitlab-kas', 'git', 'git'
    end

    context 'specified username and group' do
      before do
        stub_gitlab_rb(
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
end
