require 'chef_helper'

describe Gitaly do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'when unkown gitaly setting and new env is provided' do
    before { stub_gitlab_rb(gitaly: { enable: true, socket_path: '/tmp/socket', env: { 'TEST' => 'true' } }) }

    it 'puts the setting into the environment and maintians other environment settings' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to include('GITALY_SOCKET_PATH' => '/tmp/socket', 'TEST' => 'true')
    end

    it 'does not include known settings in the environment' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to_not include('GITALY_ENABLE')
    end
  end

  describe 'when unkown gitaly setting is provided' do
    before { stub_gitlab_rb(gitaly: { enable: true, socket_path: '/tmp/socket'}) }

    it 'puts the setting into the environment and maintians other environment settings' do
      expect(chef_run.node['gitlab']['gitaly']['env']).to include({'GITALY_SOCKET_PATH' => '/tmp/socket' })
    end
  end
end
