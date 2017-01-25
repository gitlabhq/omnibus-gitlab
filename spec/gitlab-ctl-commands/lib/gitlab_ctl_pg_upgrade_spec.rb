require 'chef_helper'

$: << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::PgUpgrade do
  before(:all) do
    @dbw = GitlabCtl::PgUpgrade.new('/fakedir')
  end

  it 'should create a new object' do
    expect(@dbw).to be_instance_of(GitlabCtl::PgUpgrade)
  end

  it 'should allow for a custom base directory' do
    expect(@dbw.base_path).to eq('/fakedir')
  end

  it 'should call gitlab-psql with the appropriate command' do
    allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command)
    expect(GitlabCtl::Util).to receive(
      :get_command_output
    ).with('su - gitlab-psql -c "fake command"')
    @dbw.run_pg_command('fake command')
  end
end
