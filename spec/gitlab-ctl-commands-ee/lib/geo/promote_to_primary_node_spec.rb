require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'fileutils'
require 'geo/promote_to_primary_node'
require 'gitlab_ctl/util'

describe Geo::PromoteToPrimaryNode, '#execute' do
  subject(:command) { described_class.new(nil, { skip_preflight_checks: true }) }

  let(:temp_directory) { Dir.mktmpdir }
  let(:gitlab_config_path) { File.join(temp_directory, 'gitlab.rb') }

  before do
    allow(command).to receive(:puts)
    allow(command).to receive(:print)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  describe '#run_preflight_checks' do
    subject(:run_preflight_checks) do
      described_class.new(nil, options).send(:run_preflight_checks)
    end

    let(:confirmation) { 'y' }

    before do
      allow(STDIN).to receive(:gets).and_return(confirmation)
    end

    context 'when `--skip-preflight-checks` is passed' do
      let(:options) { { skip_preflight_checks: true } }
      let(:confirmation) { 'n' }

      it 'does not raise error' do
        expect { run_preflight_checks }.not_to raise_error
      end
    end

    context 'when `--skip-preflight-checks` is not passed' do
      let(:options) { {} }

      it 'prints preflight check instructions' do
        expect { run_preflight_checks }.to output(
          /Ensure you have completed the following manual preflight checks/)
          .to_stdout
      end

      context 'when confirmation is accepted' do
        it 'does not raise an error' do
          expect { run_preflight_checks }.to_not raise_error
        end
      end

      context 'when confirmation is not accepted' do
        let(:confirmation) { 'n' }

        it 'raises error' do
          expect { run_preflight_checks }.to raise_error(
            RuntimeError,
            /ERROR: Manual preflight checks were not performed/
          )
        end
      end
    end
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
