require 'chef_helper'

RSpec.describe 'rails_migration' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(rails_migration)) }

  before do
    allow_any_instance_of(PgHelper).to receive(:postgresql_user).and_return('fakeuser')
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'run' do
    let(:chef_run) { runner.converge('test_gitlab::rails_migration_run') }
    let(:bash_block) { chef_run.bash('migrate gitlab-test database') }
    let(:migration_block) { chef_run.rails_migration('gitlab-test') }

    context 'when database has not been migrated' do
      before do
        allow_any_instance_of(GitlabGeoHelper).to receive(:migrated?).and_return(false)
      end

      it 'executes the bash script migration' do
        expect(chef_run).to run_bash('migrate gitlab-test database')
      end

      it 'restarts dependent_services' do
        expect(bash_block).to notify('ruby_block[test-dependent]').to(:restart)
      end
    end

    context 'when database has been migrated already' do
      it 'doesnt execute the bash script' do
        expect_any_instance_of(RailsMigrationHelper).to receive(:migrated?) { true }

        expect(chef_run).not_to run_bash('migrate gitlab-test database')
      end
    end

    context 'bash script' do
      it 'defines log file based on logfile_prefix' do
        log_file = %(log_file="/var/log/gitlab/gitlab-rails/gitlab-test-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log")

        expect(bash_block.code).to include(log_file)
      end

      it 'passes appropriate environment variables through' do
        expect(bash_block.environment).to match(hash_including('SOME_ENV'))
      end

      it 'triggers provided rake_task' do
        migrate = %(/opt/gitlab/bin/gitlab-rake gitlab:db:configure 2>& 1 | tee ${log_file})

        expect(bash_block.code).to match(/#{migrate}/)
      end

      it 'pipes exit code to db-migrate file' do
        fake_connection_digest = '63467bb60aa187d2a6830aa8f1b5cbe0'
        fake_revision = 'f9631484e7f'
        pipe = %(echo $STATUS > /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-#{fake_connection_digest}-#{fake_revision})

        expect_any_instance_of(RailsMigrationHelper).to receive(:connection_digest) { fake_connection_digest }
        expect_any_instance_of(RailsMigrationHelper).to receive(:revision) { fake_revision }

        expect(bash_block.code).to include(pipe)
      end
    end
  end
end
