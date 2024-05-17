require 'spec_helper'
$LOAD_PATH << File.join(__dir__, '../../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl/util'
require 'postgresql/decomposition_migration'

RSpec.describe PostgreSQL::DecompositionMigration do
  let(:ctl) { spy('gitlab ctl') }
  let(:confirmation) { StringIO.new('y') }
  let(:command_ok) { spy('command spy', error?: false) }
  let(:command_fail) { spy('command spy', error?: true) }
  let(:migrations_disabled) { false }

  describe '#migrate!' do
    subject(:instance) { described_class.new(ctl) }

    before do
      allow(ctl).to receive(:service_enabled?).with('postgresql').and_return(true)
      instance.instance_variable_set(:@background_migrations_initally_disabled, migrations_disabled)

      $stdin = confirmation
    end

    after do
      $stdin = STDIN
    end

    context 'when PostgreSQL is not enabled' do
      before do
        allow(ctl).to receive(:service_enabled?).with('postgresql').and_return(false)
      end

      it 'exits' do
        expect { instance.migrate! }.to raise_error(SystemExit)
      end
    end

    context 'when user does not confirm running the script' do
      let(:confirmation) { StringIO.new('n') }

      it 'exits' do
        expect { instance.migrate! }.to raise_error(SystemExit)
      end
    end

    context 'when external command fails' do
      before do
        allow(GitlabCtl::Util).to receive(:run_command).with(any_args).and_return(command_fail)
        allow(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-rails runner \"Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)\"\n",
          timeout: nil
        ).and_return(command_ok)
      end

      context 'and background migrations are enabled before starting this script' do
        it 'enables background migrations and then exits' do
          expect(GitlabCtl::Util).to receive(:run_command).with(
            "gitlab-rails runner \"Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)\"\n",
            timeout: nil
          ).and_return(command_ok)

          expect { instance.migrate! }.to raise_error(SystemExit)
        end
      end

      context 'and background migrations are disabled before starting this script' do
        let(:migrations_disabled) { true }

        it 'exits without enabling background migrations' do
          expect(GitlabCtl::Util).not_to receive(:run_command).with(
            "gitlab-rails runner \"Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)\"\n"
          )

          expect { instance.migrate! }.to raise_error(SystemExit)
        end
      end
    end

    context 'runs commands needed for migration to decomposed setup' do
      before do
        allow(GitlabCtl::Util).to receive(:run_command).with(any_args).and_return(command_ok)
      end

      context 'and background migrations are enabled before starting this script' do
        it 'disables background migrations' do
          expect(GitlabCtl::Util).to receive(:run_command).with(
            "gitlab-rails runner \"Feature.disable(:execute_background_migrations) && Feature.disable(:execute_batched_migrations_on_schedule)\"\n",
            timeout: nil
          ).and_return(command_ok)

          instance.migrate!
        end
      end

      context 'and background migrations are disabled before starting this script' do
        let(:migrations_disabled) { true }

        it 'does not not disable background migration' do
          expect(GitlabCtl::Util).not_to receive(:run_command).with(
            "gitlab-rails runner \"Feature.disable(:execute_background_migrations) && Feature.disable(:execute_batched_migrations_on_schedule)\"\n"
          )

          instance.migrate!
        end
      end

      it 'stops Gitlab except for PostgreSQL' do
        expect(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-ctl stop && gitlab-ctl start postgresql",
          timeout: nil
        ).and_return(command_ok).once

        instance.migrate!
      end

      it 'calls the migration rake task' do
        expect(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-rake gitlab:db:decomposition:migrate",
          timeout: 84_600
        ).and_return(command_ok).once

        instance.migrate!
      end

      it 'runs the reconfigure task' do
        expect(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-ctl reconfigure",
          timeout: nil
        ).and_return(command_ok).once

        instance.migrate!
      end

      it 'enables write locks' do
        expect(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-rake gitlab:db:lock_writes",
          timeout: nil
        ).and_return(command_ok).once

        instance.migrate!
      end

      it 'restarts GitLab' do
        expect(GitlabCtl::Util).to receive(:run_command).with(
          "gitlab-ctl restart",
          timeout: nil
        ).and_return(command_ok).once

        instance.migrate!
      end

      context 'and background migrations are enabled before starting this script' do
        it 'enables background migrations' do
          expect(GitlabCtl::Util).to receive(:run_command).with(
            "gitlab-rails runner \"Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)\"\n",
            timeout: nil
          ).and_return(command_ok).once

          instance.migrate!
        end
      end

      context 'and background migrations are disabled before starting this script' do
        let(:migrations_disabled) { true }

        it 'does not not enable background migration' do
          expect(GitlabCtl::Util).not_to receive(:run_command).with(
            "gitlab-rails runner \"Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)\"\n"
          )

          instance.migrate!
        end
      end
    end
  end
end
