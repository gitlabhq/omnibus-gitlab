require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::PgUpgrade do
  before do
    @fake_default_dir = '/fake/data/postgresql/data'
    allow(GitlabCtl::Util).to receive(:get_command_output).with(
      "/fakebasedir/embedded/bin/pg_ctl --version"
    ).and_return('fakeoldverision')
    @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakeoldverision', 'fakenewversion', nil, 123)
    allow(File).to receive(:realpath).with(
      @fake_default_dir
    ).and_return(@fake_default_dir)
  end

  it 'should create a new object' do
    expect(@dbw).to be_instance_of(GitlabCtl::PgUpgrade)
  end

  it 'should allow for a custom base directory' do
    expect(@dbw.base_path).to eq('/fakebasedir')
  end

  it 'should use the specified timeout' do
    expect(@dbw.timeout).to eq(123)
  end

  it 'should call pg_command with the appropriate command' do
    allow(GitlabCtl::Util).to receive(:parse_json_file).and_return(
      {
        'default' => {
          'gitlab' => {
            'postgresql' => {
              'username' => 'arbitrary-user-name'
            }
          }
        }
      })
    expect(GitlabCtl::Util).to receive(
      :get_command_output
    ).with('su - arbitrary-user-name -c "fake command"', nil, 123)
    @dbw.run_pg_command('fake command')
  end

  it 'should set tmp_data_dir to data_dir if tmp_dir is nil on initialization' do
    allow(GitlabCtl::Util).to receive(:parse_json_file).and_return({ 'default' => {} })

    expect(@dbw.tmp_data_dir).to eq(@dbw.data_dir)
  end

  it 'should return the appropriate data version' do
    allow(GitlabCtl::Util).to receive(:parse_json_file).and_return({ 'default' => {} })
    allow(File).to receive(:read).with(
      File.join(@fake_default_dir, 'PG_VERSION')
    ).and_return("99.99\n")

    expect(@dbw.fetch_data_version).to eq('99.99')
  end

  context 'when an explicit data directory is specified' do
    it 'should use it as data_dir' do
      allow(GitlabCtl::Util).to receive(:parse_json_file).and_return(
        {
          'default' => {
            'gitlab' => {
              'postgresql' => {
                'data_dir' => 'randomdir'
              }
            }
          }
        })
      allow(File).to receive(:realpath).with('randomdir').and_return('randomdir')

      expect(@dbw.data_dir).to eq('randomdir')
    end
  end

  context 'when an explicit data directory is not specified' do
    it 'should use find data_dir using dir/data' do
      allow(GitlabCtl::Util).to receive(:parse_json_file).and_return(
        {
          'default' => {
            'gitlab' => {
              'postgresql' => {
                'dir' => 'parentdir'
              }
            }
          }
        })
      allow(File).to receive(:realpath).with('parentdir/data').and_return('parentdir/data')

      expect(@dbw.data_dir).to eq('parentdir/data')
    end
  end
end
