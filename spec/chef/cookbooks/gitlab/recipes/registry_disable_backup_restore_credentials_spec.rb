require 'chef_helper'

RSpec.describe 'gitlab::registry_disable_backup_restore_credentials' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_enable))
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when backup_role is false (default)' do
    before do
      stub_gitlab_rb(
        gitlab_rails: { backup_role: false }
      )
    end

    it 'deletes all backup credential environment files' do
      expect(chef_run).to delete_file('/opt/gitlab/etc/gitlab-backup/env/env-connection')
      expect(chef_run).to delete_file('/opt/gitlab/etc/gitlab-backup/env/env-backup_user')
      expect(chef_run).to delete_file('/opt/gitlab/etc/gitlab-backup/env/env-restore_user')
    end
  end
end
