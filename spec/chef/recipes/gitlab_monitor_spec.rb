require 'chef_helper'

describe 'gitlab::gitlab-monitor' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when gitlab-monitor is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/gitlab-monitor/config') }

    before do
      stub_gitlab_rb(
        gitlab_monitor: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'gitlab-monitor', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload gitlab-monitor svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-monitor/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/gitlab-mon/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-monitor/gitlab-monitor.yml')
        .with_content { |content|
          expect(content).to match(/dead_tuples_count/)
          expect(content).to match(/git-upload-pack/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-monitor/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/gitlab-monitor/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/gitlab-monitor').with(
        owner: 'git',
        group: nil,
        mode: '0700'
      )
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        gitlab_monitor: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-monitor/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end
end
