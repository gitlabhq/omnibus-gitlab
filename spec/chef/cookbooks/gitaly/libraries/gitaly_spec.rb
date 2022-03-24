require 'chef_helper'

RSpec.describe Gitaly do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'by default' do
    it 'provides settings needed for gitaly to run' do
      expect(chef_run.node['gitaly']['env']).to include(
        'HOME' => '/var/opt/gitlab',
        'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin'
      )
    end

    it 'does not include known settings in the environment' do
      expect(chef_run.node['gitaly']['env']).not_to include('GITALY_ENABLE')
    end
  end
end
