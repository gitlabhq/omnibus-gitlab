require 'spec_helper'
require 'fileutils'
require 'geo/promote_to_primary_node'
require 'geo/promotion_preflight_checks'
require 'gitlab_ctl/util'

describe Geo::PromoteToPrimaryNode, '#execute' do
  let(:options) { { skip_preflight_checks: true } }

  subject(:command) { described_class.new(nil, options) }

  let(:temp_directory) { Dir.mktmpdir }
  let(:gitlab_config_path) { File.join(temp_directory, 'gitlab.rb') }

  before do
    allow(command).to receive(:puts)
    allow(command).to receive(:print)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  shared_examples 'runs promotion preflight checks' do |expected_args|
    it do
      expect_any_instance_of(Geo::PromotionPreflightChecks).to receive(:execute)

      command.execute
    end
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
      context 'when --confirm-primary-is-down is not passed' do
        let(:options) { {} }

        it_behaves_like 'runs promotion preflight checks',
                        '--no-confirm-primary-is-down'
      end

      context 'when --no-confirm-primary-is-down is passed' do
        let(:options) { { confirm_primary_is_down: false } }

        it_behaves_like 'runs promotion preflight checks',
                        '--no-confirm-primary-is-down'
      end

      context 'when --confirm-primary-is-down is passed' do
        let(:options) { { confirm_primary_is_down: true } }

        it_behaves_like 'runs promotion preflight checks',
                        '--confirm-primary-is-down'
      end
    end
  end

  context 'when preflight checks pass' do
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

  context 'when preflight checks fail' do
    before do
      allow(STDIN).to receive(:gets).and_return('n')
    end

    it 'raises an error' do
      expect { command.execute }.to raise_error
    end
  end
end
