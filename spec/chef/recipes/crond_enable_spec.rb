require 'chef_helper'

describe 'crond::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('crond::enable') }

  it "should create a log directory" do
    expect(chef_run).to create_directory("/var/log/gitlab/crond").with(
      owner: "root"
    )
  end

  it "should create a cron.d directory" do
    expect(chef_run).to create_directory("/var/opt/gitlab/crond").with(
      recursive: true,
      owner: "root"
    )
  end

  it_behaves_like "enabled runit service", "crond", "root", "root"
end
