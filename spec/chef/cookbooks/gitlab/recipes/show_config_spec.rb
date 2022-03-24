require 'chef_helper'

RSpec.describe 'gitlab::show_config' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::show_config') }

  it 'outputs user-defined gitlab.rb configuration to stdout' do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      patroni: { scope: 'test-cluster' }
    )

    expect { chef_run }.to output(/"scope": "test-cluster"/).to_stdout
  end

  it 'outputs GitlabCluster defined attributes to stdout' do
    GitlabCluster.config.set('primary', true)

    expect { chef_run }.to output(/"primary": true/).to_stdout
  end
end
