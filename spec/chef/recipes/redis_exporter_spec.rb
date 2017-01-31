require 'chef_helper'

describe 'gitlab::redis-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when redis-exporter is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/redis-exporter/config') }

    before do
      stub_gitlab_rb(
        redis_exporter: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'redis-exporter', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload redis-exporter svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/redis_exporter/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/redis-exporter/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/redis-exporter').with(
        owner: 'gitlab-redis',
        group: nil,
        mode: '0700'
      )
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        redis_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end
end
