require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

def stub_postgresql_json_attributes(config = nil)
  options = config || {}
  options['port'] ||= '5432'
  node_data = { 'default' => { 'postgresql' => options } }
  public_data = { 'postgresql' => options }
  allow(GitlabCtl::Util).to receive(:parse_json_file).and_return(node_data)
  allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(public_data)
end

RSpec.describe GitlabCtl::PgUpgrade do
  before do
    @fake_default_dir = '/fake/data/postgresql/data'
    allow(GitlabCtl::Util).to receive(:get_command_output).with(
      "/fakebasedir/embedded/bin/pg_ctl --version"
    ).and_return('fakeoldverision')
  end

  context 'with a default configuration' do
    before do
      stub_postgresql_json_attributes
      @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakenewversion', nil, 123)
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

    it 'should set tmp_data_dir to data_dir if tmp_dir is nil on initialization' do
      allow(GitlabCtl::Util).to receive(:parse_json_file).and_return({ 'default' => {} })

      expect(@dbw.tmp_data_dir).to eq(@dbw.data_dir)
    end

    it 'should return the appropriate data version' do
      stub_postgresql_json_attributes
      allow(File).to receive(:read).with(
        File.join(@fake_default_dir, 'PG_VERSION')
      ).and_return("99.99\n")

      expect(@dbw.fetch_data_version).to eq('99.99')
    end

    context 'when determining if there is enough free space to perform an upgrade' do
      before do
        stub_postgresql_json_attributes
      end

      it 'detects when there is not enough available disk space for upgrade' do
        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "du -s --block-size=1m #{@dbw.data_dir}", nil, 123
        ).and_return("200000\n#{@dbw.data_dir}")

        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "df -P --block-size=1m #{@dbw.data_dir} | awk '{print $4}'", nil, 123
        ).and_return("Available\n300000")

        expect(@dbw.enough_free_space?(@dbw.data_dir)).to eq(false)
      end

      it 'detects when there is enough available disk space for upgrade' do
        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "du -s --block-size=1m #{@dbw.data_dir}", nil, 123
        ).and_return("200000\n#{@dbw.data_dir}")

        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "df -P --block-size=1m #{@dbw.data_dir} | awk '{print $4}'", nil, 123
        ).and_return("Available\n450000")

        expect(@dbw.enough_free_space?(@dbw.data_dir)).to eq(true)
      end
    end
  end

  it 'should use the configured port when running pg_upgrade' do
    stub_postgresql_json_attributes({ 'port' => '1959' })
    @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakenewversion', nil, 123)
    expect(@dbw.port).to eq('1959')
  end

  it 'should call pg_command with the appropriate command' do
    stub_postgresql_json_attributes({ 'username' => 'arbitrary-user-name' })
    @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakenewversion', nil, 123)
    expect(GitlabCtl::Util).to receive(
      :get_command_output
    ).with('su - arbitrary-user-name -c "fake command"', nil, 123)
    @dbw.run_pg_command('fake command')
  end

  context 'when an explicit data directory is specified' do
    it 'should use it as data_dir' do
      stub_postgresql_json_attributes({ 'data_dir' => 'randomdir' })
      @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakenewversion', nil, 123)

      expect(@dbw.data_dir).to eq('randomdir')
    end
  end

  context 'when an explicit data directory is not specified' do
    it 'should use find data_dir using dir/data' do
      stub_postgresql_json_attributes({ 'dir' => 'parentdir' })
      @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fake/data', 'fakenewversion', nil, 123)

      expect(@dbw.data_dir).to eq('parentdir/data')
    end
  end
end
