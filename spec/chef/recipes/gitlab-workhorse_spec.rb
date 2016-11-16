require 'chef_helper'

describe 'gitlab::gitlab-workhorse' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with environment variables' do
    context 'by default' do
      it_behaves_like "enabled gitlab-workhorse env", "HOME", '\/var\/opt\/gitlab'
      it_behaves_like "enabled gitlab-workhorse env", "PATH", '\/opt\/gitlab\/bin:\/opt\/gitlab\/embedded\/bin:\/bin:\/usr\/bin'

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { env: { 'IAM' => 'CUSTOMVAR'}})
        end

        it_behaves_like "enabled gitlab-workhorse env", "IAM", 'CUSTOMVAR'
      end
    end
  end

  context 'without api rate limiting' do
    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiLimit/)
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueDuration/)
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueLimit/)
    end
  end

  context 'with api rate limiting' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { api_limit: 3, api_queue_limit: 6, api_queue_duration: '1m' })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiLimit 3 \\/)
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueDuration 1m \\/)
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueLimit 6 \\/)
    end
  end
end
