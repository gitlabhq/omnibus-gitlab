require 'chef_helper'

describe 'gitlab::sidekiq' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default values' do
    it 'correctly renders out the sidekiq service file' do
        expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-C \/opt\/gitlab\/embedded\/service\/.*\/config\/sidekiq_queues.yml/)
    end
  end
end
