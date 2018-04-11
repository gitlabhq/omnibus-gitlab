require 'chef_helper'

describe 'go-crond::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('go-crond::enable') }

  it "should create a log directory" do
    expect(chef_run).to create_directory("/var/log/gitlab/go-crond").with(
      owner: "root"
    )
  end

  it "should create a cron.d directory" do
    expect(chef_run).to create_directory("/var/opt/gitlab/go-crond").with(
      recursive: true,
      owner: "root"
    )
  end

  it_behaves_like "enabled runit service", "go-crond", "root", "root"
end
