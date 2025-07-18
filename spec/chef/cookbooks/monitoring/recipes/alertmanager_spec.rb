require 'chef_helper'

alertmanager_yml_output = <<-ALERTMANAGERYML
  ---
  global:
    smtp_from: gitlab-omnibus
    smtp_smarthost: testhost:25
  templates: []
  route:
    receiver: default-receiver
    routes: []
  receivers:
  - name: default-receiver
    email_configs:
    - to: admin@example.com
  inhibit_rules: []
ALERTMANAGERYML

RSpec.describe 'monitoring::alertmanager' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'GODEBUG' => 'tlsmlkem=0',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when alertmanager is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/alertmanager/log/config') }

    before do
      stub_gitlab_rb(
        prometheus: { enable: true },
        alertmanager: {
          enable: true,
          admin_email: 'admin@example.com',
        },
        gitlab_rails: {
          gitlab_email_from: 'gitlab-omnibus',
          smtp_enable: true,
          smtp_address: 'testhost',
          smtp_port: 25,
        }
      )
    end

    it_behaves_like 'enabled runit service', 'alertmanager', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/alertmanager/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/alertmanager/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/alertmanager/)
          expect(content).to match(/alertmanager.yml/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/alertmanager/alertmanager.yml')
        .with_content(alertmanager_yml_output.gsub(/^ {2}/, ''))

      expect(chef_run).to render_file('/opt/gitlab/sv/alertmanager/log/run')
        .with_content(/svlogd -tt \/var\/log\/gitlab\/alertmanager/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/opt/gitlab/alertmanager').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0750'
      )
    end

    it 'should create a gitlab-prometheus user account' do
      expect(chef_run).to create_account('Prometheus user and group').with(username: 'gitlab-prometheus')
    end

    it 'sets a default listen address' do
      expect(chef_run).to render_file('/opt/gitlab/sv/alertmanager/run')
        .with_content(/web.listen-address=localhost:9093/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        prometheus: { enable: true },
        alertmanager: {
          listen_address: ':9093',
          enable: true,
          env: {
            'USER_SETTING' => 'asdf1234'
          },
          global: {
            'smtp_from' => 'override_value'
          }
        },
        gitlab_rails: {
          smtp_enable: true,
          smtp_address: 'other-testhost',
          smtp_port: 465,
          smtp_from: 'default_value'
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/alertmanager/run')
        .with_content(/web.listen-address=:9093/)
    end

    it 'keeps the defaults that the user did not override' do
      expect(chef_run).to render_file('/var/opt/gitlab/alertmanager/alertmanager.yml')
        .with_content(/receiver: default-receiver/)
    end

    it 'renders alertmanager.yml with the non-default value' do
      expect(chef_run).to render_file('/var/opt/gitlab/alertmanager/alertmanager.yml')
        .with_content(/smtp_smarthost: other-testhost:465/)
    end

    it 'renders alertmanager.yml with the user override value' do
      expect(chef_run).to render_file('/var/opt/gitlab/alertmanager/alertmanager.yml')
        .with_content(/smtp_from: override_value/)
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/alertmanager/env').with_variables(
        default_vars.merge(
          {
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      it_behaves_like 'enabled logged service', 'alertmanager', true, { log_directory_owner: 'gitlab-prometheus' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          alertmanager: {
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'alertmanager', true, { log_directory_owner: 'gitlab-prometheus', log_group: 'fugee' }
    end
  end
end
