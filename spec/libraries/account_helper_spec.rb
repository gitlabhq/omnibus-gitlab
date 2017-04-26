require 'chef_helper'

describe AccountHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  it 'returns a list of users' do
    expect(AccountHelper.new(chef_run.node).users).to eq(
      %w(git gitlab-www gitlab-redis gitlab-ci gitlab-psql gitlab-redis mattermost registry gitlab-prometheus)
    )
  end

  it 'returns a list of groups' do
    expect(AccountHelper.new(chef_run.node).groups).to eq(
      %w(git gitlab-www gitlab-redis gitlab-ci gitlab-redis gitlab-psql mattermost registry)
    )
  end

end
