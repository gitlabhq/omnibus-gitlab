require 'spec_helper'
require 'fileutils'
require 'geo/promote_to_primary_node'
require 'geo/promotion_preflight_checks'
require 'gitlab_ctl/util'

RSpec.describe Geo::PromoteToPrimaryNode, '#execute' do
  let(:options) { { skip_preflight_checks: true } }

  subject(:command) { described_class.new(nil, options) }

  let(:temp_directory) { Dir.mktmpdir }
  let(:gitlab_config_path) { File.join(temp_directory, 'gitlab.rb') }

  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)

    allow(command).to receive(:run_command).with(any_args)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  describe '#run_preflight_checks' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    context 'when `--skip-preflight-checks` is passed' do
      it 'does not run execute promotion preflight checks' do
        expect_any_instance_of(Geo::PromotionPreflightChecks).not_to receive(:execute)

        command.execute
      end
    end

    context 'when `--skip-preflight-checks` is not passed' do
      let(:options) { { confirm_primary_is_down: true } }

      before do
        allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
          :execute).and_return(true)
      end

      it 'runs preflight checks' do
        expect_any_instance_of(Geo::PromotionPreflightChecks).to receive(:execute)

        command.execute
      end

      it 'passes given options to preflight checks command' do
        expect(Geo::PromotionPreflightChecks).to receive(:new).with(
          nil, options).and_call_original

        command.execute
      end
    end
  end

  context 'when preflight checks pass' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
        :execute).and_return(true)

      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    context 'when running in force mode' do
      let(:options) { { force: true } }

      it 'does not ask for final confirmation' do
        expect { command.execute }.not_to output(
          /WARNING\: Secondary will now be promoted to primary./).to_stdout
      end
    end

    context 'when not running in force mode' do
      let(:options) { { force: false } }

      it 'asks for confirmation' do
        expect { command.execute }.to output(
          /WARNING\: Secondary will now be promoted to primary./).to_stdout
      end

      context 'when final confirmation is given' do
        it 'calls the next subcommand' do
          expect(command).to receive(:promote_postgresql_to_primary)

          command.execute
        end
      end
    end
  end

  context 'when preflight checks fail' do
    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      allow(STDIN).to receive(:gets).and_return('n')

      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)

      allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
        :execute).and_raise(SystemExit)
    end

    context 'when running in force mode' do
      let(:options) { { force: true } }

      it 'asks for confirmation' do
        expect { command.execute }.to output(
          /Are you sure you want to proceed?/
        ).to_stdout
      end

      it 'exits with 1 if user denies' do
        allow(STDIN).to receive(:gets).and_return('n')

        expect { command.execute }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'calls all the subcommands if user affirms' do
        allow(STDIN).to receive(:gets).and_return('y')

        is_expected.to receive(:promote_postgresql_to_primary)
        is_expected.to receive(:reconfigure)
        is_expected.to receive(:promote_to_primary)

        command.execute
      end
    end

    context 'when not running in force mode' do
      let(:options) { { force: false } }

      it 'exits with 1' do
        expect { command.execute }.to raise_error(SystemExit)
      end
    end
  end
end
