require_relative '../../files/gitlab-cookbooks/gitlab/libraries/helper.rb'
require 'chef_helper'

describe PgHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

  it 'returns a valid version' do
    helper = PgHelper.new(node)
    allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version').and_return("YYYYYYYY XXXXXXX")
    expect(helper.version).to eq("XXXXXXX") 
  end
end
