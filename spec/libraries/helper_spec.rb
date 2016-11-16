require 'chef_helper'

describe PgHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

  before do
    allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version').and_return("YYYYYYYY XXXXXXX")
  end

  it 'returns a valid version' do
    helper = PgHelper.new(node)
    expect(helper.version).to eq("XXXXXXX")
  end
end
