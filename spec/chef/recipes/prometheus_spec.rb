require 'chef_helper'

describe 'gitlab::prometheus' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when prometheus is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/prometheus/config') }

    before do
      stub_gitlab_rb(
        prometheus: {
          enable: true
        }
      )
    end

    it_behaves_like 'enabled runit service', 'prometheus', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload prometheus svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/prometheus/)
          expect(content).to match(/prometheus.yml/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content { |content|
          expect(content).to match(/scrape_interval: 15s/)
          expect(content).to match(/scrape_timeout: 15s/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/prometheus/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0750'
      )
    end

    it 'should create a gitlab-prometheus user account' do
      expect(chef_run).to create_user('gitlab-prometheus')
    end
  end

  context 'when storage path is changed' do
    before do
      stub_gitlab_rb(
        prometheus: {
          flags: { 'storage.local.path' => 'foo' },
          enable: true
        }
      )
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
    end
  end

  context 'when scrape_interval is changed' do
    before do
      stub_gitlab_rb(
        prometheus: {
          scrape_interval: 9999,
          enable: true
        }
      )
    end

    it 'renders prometheus.yml with the non-default value' do
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_interval: 9999s/)
    end
  end

  context 'when scrape_timeout is changed' do
    before do
      stub_gitlab_rb(
        prometheus: {
          scrape_timeout: 8888,
          scrape_interval: 11,
          enable: true
        }
      )
    end

    it 'renders prometheus.yml with the non-default value' do
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_timeout: 8888s/)
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_interval: 11/)
    end
  end
end
