require 'chef_helper'

RSpec.describe 'mattermost::disable' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'is always loaded under the default configuration' do
    expect(chef_run).to include_recipe('mattermost::disable')
  end

  it 'declares the mattermost runit service as disabled' do
    expect(chef_run).to disable_runit_service('mattermost')
  end
end
