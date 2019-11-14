require 'chef_helper'

describe 'package::runit_systemd' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'package::runit_systemd') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'setting TasksMax value' do
    context 'when systemd version < 227' do
      before do
        allow(SystemdHelper).to receive(:systemd_version).and_return(200)
      end

      it 'does not include TasksMax setting in unit file' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service')
        expect(chef_run).not_to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('TasksMax=4915')
      end
    end

    context 'when systemd version >= 227' do
      before do
        allow(SystemdHelper).to receive(:systemd_version).and_return(235)
      end

      it 'include TasksMax setting in unit file' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('TasksMax=4915')
      end
    end

    context 'with user provided value for TasksMax' do
      before do
        stub_gitlab_rb(
          package: { systemd_tasks_max: 10000 }
        )
        allow(SystemdHelper).to receive(:systemd_version).and_return(235)
      end

      it 'sets correct value for TasksMax in unit file' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('TasksMax=10000')
      end
    end
  end

  describe 'setting WantedBy and After settings for unit file' do
    context 'by default' do
      it 'uses "multi-user.target" for WantedBy' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('WantedBy=multi-user.target')
      end

      it 'uses "multi-user.target" for WantedBy' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('After=multi-user.target')
      end
    end

    context 'when WantedBy is specified' do
      before do
        stub_gitlab_rb(
          package: { systemd_wanted_by: 'basic.target' }
        )
      end

      it 'uses specified value for WantedBy' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('WantedBy=basic.target')
      end

      it 'uses value specified for WantedBy for After also' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('After=basic.target')
      end
    end

    context 'when both WantedBy and After are specified' do
      before do
        stub_gitlab_rb(
          package: {
            systemd_wanted_by: 'foo',
            systemd_after: 'bar'
          }
        )
      end

      it 'uses specified value for WantedBy' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('WantedBy=foo')
      end

      it 'uses specified value for After, not value given for WantedBy' do
        expect(chef_run).to render_file('/usr/lib/systemd/system/gitlab-runsvdir.service').with_content('After=bar')
      end
    end
  end
end
