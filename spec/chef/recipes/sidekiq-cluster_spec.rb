require 'chef_helper'

describe 'gitlab-ee::sidekiq-cluster' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when sidekiq-cluster is disabled' do
    before { stub_gitlab_rb(sidekiq_cluster: { enable: false }) }

    it 'does not render the sidekiq-cluster service file' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
    end
  end

  context 'with queue_groups set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run").with_content(/process_commit,post_receive/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run").with_content(/gitlab_shell/)
    end
  end

  context 'with interval set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       interval: 10,
                       queue_groups: ['process_commit,post_receive']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run").with_content(/\-i 10/)
    end
  end
end
