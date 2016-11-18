require 'chef_helper'

describe PgHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
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
      '/var/opt/gitlab/postgresql/data/PG_VERSION'
    ).and_return('111.222')
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with(
      '/opt/gitlab/embedded/postgresql/*'
    ).and_return(['111.222.1', '111.222.2', '111.222.18', 'AAA.BBB'])
    # We mock this in chef_helper.rb. Overide the mock to call the original 
    allow_any_instance_of(PgHelper).to receive(:database_version).and_call_original
    expect(@helper.database_version).to eq('111.222.18')
  end

  it 'returns a list of installed binary files' do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with(
      '/opt/gitlab/embedded/postgresql/fake_version/bin/*'
    ).and_return(
      %w(
        /opt/gitlab/embedded/postgresql/fake_version/bin/pgone
        /opt/gitlab/embedded/postgresql/fake_version/bin/pgtwo
        /opt/gitlab/embedded/postgresql/fake_version/bin/pgthree
      )
    )
    expect(@helper.bin_files('fake_version')).to eq(%w(pgone pgtwo pgthree))
  end
end
