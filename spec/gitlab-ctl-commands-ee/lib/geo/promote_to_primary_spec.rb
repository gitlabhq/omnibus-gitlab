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
  let(:gitlab_config_path) { File.join(temp_directory, 'gitlab.rb') }

  before do
    allow(command).to receive(:puts)
    allow(command).to receive(:print)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  context 'when confirmation is accepted' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')
    end

    it 'calls all the subcommands' do
      is_expected.to receive(:run_command).with('gitlab-ctl reconfigure', live: true).once
      is_expected.to receive(:run_command).with('gitlab-rake geo:set_secondary_as_primary', live: true).once

      shell_out_object = double.tap { |shell_out_object| expect(shell_out_object).to receive(:error!) }
      is_expected.to receive(:run_command).with("/opt/gitlab/embedded/bin/gitlab-pg-ctl promote", live: true).once.and_return(shell_out_object)

      command.execute
    end
  end

  context 'when confirmation is refused' do
    before do
      allow(STDIN).to receive(:gets).and_return('n')
    end

    it 'calls all the subcommands' do
      is_expected.not_to receive(:run_command)

      expect { command.execute }.to raise_error RuntimeError, 'Exited because primary node must be down'
    end
  end
end
