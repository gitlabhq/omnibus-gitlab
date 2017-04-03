require 'chef_helper'
require 'base64'

describe 'gitlab_rails' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  context 'when there is a legacy GitLab Rails stuck_ci_builds_worker_cron key' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(gitlab_rails: { stuck_ci_builds_worker_cron: '0 1 2 * *' })
    end

    it 'warns that this value is deprecated' do
      allow(Chef::Log).to receive(:warn).and_call_original
      expect(Chef::Log).to receive(:warn).with(/gitlab_rails\['stuck_ci_builds_worker_cron'\]/)

      chef_run
    end

    it 'copies legacy value from legacy key to new one' do
      chef_run

      expect(Gitlab['gitlab_rails']['stuck_ci_jobs_worker_cron']).to eq('0 1 2 * *')
    end
  end
end
