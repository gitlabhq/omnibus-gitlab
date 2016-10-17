require 'chef_helper'

describe 'gitlab::prometheus' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when prometheus is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/prometheus/config') }

    it_behaves_like "enabled runit service", "prometheus", "root", "root"

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload prometheus svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/exec chpst -P/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/\/opt\/gitlab\/embedded\/bin\/prometheus/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/prometheus.yml/)

      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_interval: 15s/)

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/prometheus/)
    end
  end

  context 'when storage path is changed' do
    before do
      stub_gitlab_rb(prometheus: {flags: {'storage.local.path': 'foo'}})
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
    end
  end
end
