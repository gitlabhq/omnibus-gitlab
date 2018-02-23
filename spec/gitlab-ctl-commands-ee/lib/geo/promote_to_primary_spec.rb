require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'fileutils'
require 'geo/promote_to_primary'
require 'fileutils'
require 'gitlab_ctl/util'

describe Geo::PromoteToPrimary, '#execute' do
  subject(:command) { described_class.new(nil, {}) }

  let(:temp_directory) { Dir.mktmpdir }
  let(:postgres_trigger_file_path) { File.join(temp_directory, 'test_trigger') }
  let(:gitlab_config_path) { File.join(temp_directory, 'gitlab.rb') }
  let(:key_path) { File.join(temp_directory, 'id_rsa') }
  let(:public_key_path) { File.join(temp_directory, 'id_rsa.pub') }

  before do
    allow(STDIN).to receive(:gets).and_return('y')
    allow(command).to receive(:puts)
    allow(command).to receive(:print)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  it 'calls all the subcommands' do
    stub_env

    is_expected.to receive(:run_command).with('gitlab-ctl reconfigure', live: true).once
    is_expected.to receive(:run_command).with('gitlab-rake geo:set_secondary_as_primary', live: true).once
    is_expected.to receive(:run_command).with("touch #{postgres_trigger_file_path}").once

    command.execute
  end

  it 'applies all the changes' do
    stub_env

    allow(command).to receive(:run_command) do |cmd|
      fake_run_command(cmd)
    end

    command.execute

    expect(@reconfigure_has_been_run).to be_truthy
    expect(@rake_task_has_been_run).to be_truthy
    expect(File.exist?(postgres_trigger_file_path)).to be_truthy
    expect(File.exist?(key_path)).to be_falsey
    expect(File.exist?(public_key_path)).to be_falsey
  end

  def stub_env
    FileUtils.rm_f(postgres_trigger_file_path)
    stub_const("Geo::PromoteToPrimary::TRIGGER_FILE_PATH", postgres_trigger_file_path)
    allow(subject).to receive(:key_path).and_return(key_path)
    allow(subject).to receive(:public_key_path).and_return(public_key_path)
  end

  def fake_run_command(cmd)
    if cmd == 'gitlab-ctl reconfigure'
      @reconfigure_has_been_run = true
      return
    end

    if cmd == 'gitlab-rake geo:set_secondary_as_primary'
      @rake_task_has_been_run = true
      return
    end

    GitlabCtl::Util.run_command(cmd)
  end
end
