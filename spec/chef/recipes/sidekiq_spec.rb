require 'chef_helper'

describe 'gitlab::sidekiq' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default values' do
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-C \/opt\/gitlab\/embedded\/service\/.*\/config\/sidekiq_queues.yml/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-t 4/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-c 25/)
    end
  end

  context 'with specified values' do
    before do
      stub_gitlab_rb(sidekiq: { shutdown_timeout: 8, concurrency: 35 })
    end
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-t 8/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-c 35/)
    end
  end
end
