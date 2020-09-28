require 'spec_helper'
require 'geo/promotion_preflight_checks'
require 'gitlab_ctl/util'

RSpec.describe Geo::PromotionPreflightChecks, '#execute' do
  let(:confirmation) { 'y' }
  let(:options) { { confirm_primary_is_down: true } }

  subject(:command) { described_class.new(nil, options) }

  before do
    allow(STDIN).to receive(:gets).and_return(confirmation)
    allow(command).to receive(:run_command).with(any_args)

    shell_out_object = double.tap do |shell_out_object|
      allow(shell_out_object).to receive(:stdout).and_return('SUCCESS')
      allow(shell_out_object).to receive(:error?).and_return(false)
    end

    allow(command).to receive(:run_command).with(
      'gitlab-rake gitlab:geo:check_replication_verification_status')
      .and_return(shell_out_object)
  end

  it 'prints preflight check instructions' do
    expect { command.execute }.to output(
      /Ensure you have completed the following manual preflight checks/)
      .to_stdout
  end

  context 'when manual checks are confirmed' do
    it 'does not raise an error' do
      expect { command.execute }.to_not raise_error
    end

    it 'runs `check_replication_verification_status` task' do
      is_expected.to receive(:run_command).with(
        'gitlab-rake gitlab:geo:check_replication_verification_status').once

      command.execute
    end

    context 'when gitlab:geo:check_replication_verification_status fails' do
      around do |example|
        example.run
      rescue SystemExit
      end

      before do
        shell_out_object = double.tap do |shell_out_object|
          allow(shell_out_object).to receive(:stdout).and_return('error message')
          allow(shell_out_object).to receive(:error?).and_return(true)
        end

        allow(command).to receive(:run_command).with(
          'gitlab-rake gitlab:geo:check_replication_verification_status')
          .once
          .and_return(shell_out_object)
      end

      it 'prints error message when rake task errors' do
        expect { command.execute }.to output(
          /error message\nERROR: Replication\/verification is incomplete./).to_stdout
      end

      it 'exits with 1 when rake task errors' do
        expect { command.execute }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when gitlab:geo:check_replication_verification_status passes' do
      it 'prints a success message' do
        expect { command.execute }.to output(
          /All preflight checks have passed. This node can now be promoted./)
          .to_stdout
      end
    end
  end

  context 'when manual checks are not confirmed' do
    let(:confirmation) { 'n' }

    around do |example|
      example.run
    rescue SystemExit
    end

    it 'print error message' do
      expect { command.execute }.to output(
        /ERROR: Manual preflight checks were not performed/
      ).to_stdout
    end
  end

  describe 'option --confirm-primary-is-down' do
    before do
      allow(command).to receive(:confirm_manual_checks).and_return(true)
    end

    context 'when the option is not passed' do
      let(:options) { {} }
      let(:confirmation) { 'n' }

      around do |example|
        example.run
      rescue SystemExit
      end

      it 'asks user for confirmation' do
        expect { command.execute }.to output(
          /Is primary down? (N\/y)/)
          .to_stdout
      end

      it 'prints an error message when user doesn not select y/Y' do
        expect { command.execute }.to output(
          /ERROR: Primary node must be down./)
          .to_stdout
      end
    end

    context 'when the option is passed' do
      it 'does not ask user for confirmation' do
        expect { command.execute }.not_to output(
          /Is primary down? (N\/y)/)
          .to_stdout
      end
    end
  end

  context 'when all checks pass' do
    before do
      allow(command).to receive(:confirm_manual_checks).and_return(true)
      allow(command).to receive(:confirm_primary_is_down).and_return(true)
    end

    it 'prints a success message' do
      expect { command.execute }.to output(
        /All preflight checks have passed. This node can now be promoted./)
        .to_stdout
    end
  end
end
