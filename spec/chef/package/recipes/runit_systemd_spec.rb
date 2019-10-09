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
end
