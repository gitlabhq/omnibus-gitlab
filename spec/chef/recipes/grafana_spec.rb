require 'chef_helper'

describe 'gitlab::grafana' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when grafana is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/grafana/config') }

    before do
      stub_gitlab_rb(
        grafana: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'grafana', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/grafana/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/grafana-server/)
          expect(content).to match(/-config '\/var\/opt\/gitlab\/grafana\/grafana.ini'/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/grafana/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/grafana').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
    end

    it 'creates the configuration file' do
      expect(chef_run).to create_template('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/http_addr = localhost/)
          expect(content).to match(/http_port = 3000/)
          expect(content).to match(/root_url = %(protocol)s:\/\/%(domain)s\/-\/grafana\//)
        }
    end
  end

  context 'when grafana is enabled and prometheus is disabled' do
    before do
      stub_gitlab_rb(
        prometheus: { enable: false },
        grafana: { enable: true }
      )
    end

    it 'should create the gitlab-prometheus account if prometheus is disabled' do
      expect(chef_run).to create_account('Prometheus user and group').with_username('gitlab-prometheus')
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        grafana: {
          log_directory: 'foo',
          enable: true
        }
      )
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        grafana: {
          http_addr: '0.0.0.0',
          http_port: 3333,
          enable: true,
          env: {
            'USER_SETTING' => 'asdf1234'
          }
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to create_template('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/http_addr = 0.0.0.0/)
          expect(content).to match(/http_port = 3000/)
        }
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/grafana/env').with_variables(
        default_vars.merge(
          {
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end
  end
end
