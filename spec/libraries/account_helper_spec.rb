require 'chef_helper'

describe AccountHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  it 'returns a list of users' do
    expect(AccountHelper.new(chef_run.node).users).to eq(
      %w(git gitlab-www gitlab-redis gitlab-psql mattermost registry gitlab-prometheus gitlab-consul)
    )
  end

  it 'returns a list of groups' do
    expect(AccountHelper.new(chef_run.node).groups).to eq(
      %w(git gitlab-www gitlab-redis gitlab-psql mattermost registry gitlab-consul gitlab-prometheus)
    )
  end
end
