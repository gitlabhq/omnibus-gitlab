require 'chef_helper'

RSpec.describe 'monitoring::node-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when node-exporter is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/node-exporter/log/config') }

    before do
      stub_gitlab_rb(
        node_exporter: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'node-exporter', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/node-exporter/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/node_exporter/)
          expect(content).to match(/--collector\.mountstats /)
          expect(content).to match(/--collector\.runit /)
          expect(content).to match(/--collector\.runit.servicedir=\/opt\/gitlab\/sv /)
          expect(content).to match(/\/textfile_collector/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/node-exporter/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/node-exporter').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/node-exporter/textfile_collector').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0755'
      )
    end

    it 'sets a default listen address' do
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content(/web.listen-address=localhost:9100/)
    end
  end

  context 'when node-exporter is enabled and prometheus is disabled' do
    before do
      stub_gitlab_rb(
        prometheus: { enable: false },
        node_exporter: { enable: true }
      )
    end

    it 'should create the gitlab-prometheus account if prometheus is disabled' do
      expect(chef_run).to create_account('Prometheus user and group').with_username('gitlab-prometheus')
    end
  end

  context 'when node-exporter is enabled and prometheus is enabled' do
    before do
      stub_gitlab_rb(
        prometheus: { enable: true },
        node_exporter: { enable: true }
      )
    end

    it 'creates a node.rules file' do
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/rules/node.rules')
        .with_content(/instance:node_cpus:count/)
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        node_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        node_exporter: {
          flags: {
            'collector.textfile.directory' => '/tmp',
            'collector.arp' => false,
            'collector.mountstats' => false
          },
          listen_address: 'localhost:9899',
          enable: true,
          env: {
            'USER_SETTING' => 'asdf1234'
          }
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content { |content|
          expect(content).to match(/web\.listen-address=localhost:9899/)
          expect(content).to match(/collector\.textfile\.directory=\/tmp/)
          expect(content).to match(/--no-collector\.arp/)
          expect(content).to match(/--no-collector\.mountstats/)
          expect(content).to match(/--collector\.runit/)
        }
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/node-exporter/env').with_variables(
        default_vars.merge(
          {
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end
  end

  include_examples "consul service discovery", "node_exporter", "node-exporter"
end
