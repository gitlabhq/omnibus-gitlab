require 'chef_helper'

$: << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::PgUpgrade do
  before(:all) do
    @dbw = GitlabCtl::PgUpgrade.new('/fakebasedir', '/fakedatadir')
  end

  it 'should create a new object' do
    expect(@dbw).to be_instance_of(GitlabCtl::PgUpgrade)
  end

  it 'should allow for a custom base directory' do
    expect(@dbw.base_path).to eq('/fakebasedir')
  end

  it 'should call gitlab-psql with the appropriate command' do
    allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command)
    expect(GitlabCtl::Util).to receive(
      :get_command_output
    ).with('su - gitlab-psql -c "fake command"')
    @dbw.run_pg_command('fake command')
  end

  it 'should set tmp_data_dir to data_dir if tmp_dir is nil on initialization' do
    fake_default_dir = '/fake/data/postgresql/data'
    allow(File).to receive(:realpath).with(
      fake_default_dir
    ).and_return(fake_default_dir)
    db_worker = GitlabCtl::PgUpgrade.new('/fake/base', '/fake/data')
    expect(db_worker.tmp_data_dir).to eq(db_worker.data_dir)
  end
end
