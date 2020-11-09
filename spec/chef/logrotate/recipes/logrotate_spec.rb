require 'chef_helper'

RSpec.describe 'logrotate' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when logrotate is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/logrotate/log/config') }

    it_behaves_like "enabled runit service", "logrotate", "root", "root"

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/run')
        .with_content(/cd \/var\/opt\/gitlab\/logrotate/)
      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/run')
        .with_content(/exec \/opt\/gitlab\/embedded\/bin\/chpst -P \/usr\/bin\/env/)
      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/run')
        .with_content(/\/opt\/gitlab\/embedded\/bin\/gitlab-logrotate-wrapper/)

      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/logrotate/)

      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/log/config')
        .with_content(/s209715200/)
      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/log/config')
        .with_content(/n30/)
      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/log/config')
        .with_content(/t86400/)
      expect(chef_run).to render_file('/opt/gitlab/sv/logrotate/log/config')
        .with_content(/!gzip/)
    end

    it 'executes start command' do
      expect(chef_run).to run_execute('/opt/gitlab/bin/gitlab-ctl start logrotate').with(retries: 20)
    end
  end

  context 'when logrotate is disabled' do
    before do
      stub_gitlab_rb(logrotate: { enable: false })
    end

    it_behaves_like "disabled runit service", "logrotate"

    it 'does not execute the start command' do
      expect(chef_run).not_to run_execute('/opt/gitlab/bin/gitlab-ctl start logrotate').with(retries: 20)
    end
  end
end
