require 'chef_helper'

describe Gitaly do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'by default' do
    it 'provides settings needed for gitaly to run' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to include(
        'HOME' => '/var/opt/gitlab',
        'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin'
      )
    end

    it 'does not include known settings in the environment' do
      expect(chef_run.node['gitlab']['gitaly']['env']).not_to include('GITALY_ENABLE')
    end
  end

  describe 'when unknown gitaly setting and new env is provided' do
    before { stub_gitlab_rb(gitaly: { cool_feature: true, env: { 'TEST' => 'true' } }) }

    it 'puts the setting into the environment and maintains other environment settings' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to include('GITALY_COOL_FEATURE' => 'true', 'TEST' => 'true')
    end

    it 'does not include known settings in the environment' do
      expect(chef_run.node['gitlab']['gitaly']['env']).not_to include('GITALY_ENABLE')
    end
  end

  describe 'when unkown gitaly setting is provided' do
    before { stub_gitlab_rb(gitaly: { cool_feature: true }) }

    it 'puts the setting into the environment and maintians other environment settings' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to include({ 'GITALY_COOL_FEATURE' => 'true' })
    end
  end
end
