require 'chef_helper'

RSpec.describe 'registry::disable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(registry: { enable: false })
  end

  it 'disables the registry service' do
    expect(chef_run).to disable_runit_service('registry')
  end
end
