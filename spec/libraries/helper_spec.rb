require 'chef_helper'

describe PgHelper do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['postgresql']['data_dir'] = '/fakedir'
      node.set['package']['install-dir'] = '/fake/install/dir'
    end.converge('gitlab::default')
  end
  let(:node) { chef_run.node }

  before do
    allow(VersionHelper).to receive(:version).with(
      '/opt/gitlab/embedded/bin/psql --version'
    ).and_return('YYYYYYYY XXXXXXX')
    @helper = PgHelper.new(node)
  end

  it 'returns a valid version' do
    expect(@helper.version).to eq('XXXXXXX')
  end

  it 'returns a valid database_version' do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(
      '/fakedir/PG_VERSION'
    ).and_return('111.222')
    allow(Dir).to receive(:glob).with(
      '/fake/install/dir/embedded/postgresql/*'
    ).and_return(['111.222.18', '222.333.11'])
    # We mock this in chef_helper.rb. Overide the mock to call the original
    allow_any_instance_of(PgHelper).to receive(:database_version).and_call_original
    expect(@helper.database_version).to eq('111.222.18')
  end
end
