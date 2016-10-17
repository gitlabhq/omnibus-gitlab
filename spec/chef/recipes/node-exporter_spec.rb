require 'chef_helper'

describe 'gitlab::node-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when node-exporter is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/node-exporter/config') }

    it_behaves_like "enabled runit service", "node-exporter", "root", "root"

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload node-exporter svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content(/exec chpst -P/)
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content(/\/opt\/gitlab\/embedded\/bin\/node_exporter/)
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/run')
        .with_content(/\/textfile_collector/)

      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/node-exporter/)
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(node_exporter: {log_directory: 'foo'})
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/node-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end
end
