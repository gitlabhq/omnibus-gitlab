require 'chef_helper'

RSpec.describe 'postgresql::user' do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'postgresql::sysctl') }

  it 'creates sysctl files' do
    expect(chef_run).to create_gitlab_sysctl('kernel.shmmax').with_value(17179869184)
    expect(chef_run).to create_gitlab_sysctl('kernel.shmall').with_value(4194304)
  end
end
