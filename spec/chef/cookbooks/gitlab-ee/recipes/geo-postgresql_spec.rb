require 'chef_helper'

RSpec.describe 'geo postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:postgresql_conf) { '/var/opt/gitlab/geo-postgresql/data/postgresql.conf' }
  let(:runtime_conf) { '/var/opt/gitlab/geo-postgresql/data/runtime.conf' }
  let(:pg_hba_conf) { '/var/opt/gitlab/geo-postgresql/data/pg_hba.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('best_version'))
    allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('best_version'))
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return(PGVersion.new('best_version'))

    # Workaround for Chef reloading instances across different examples
    allow_any_instance_of(GeoPgHelper).to receive(:bootstrapped?).and_return(true)
    allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
    allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('geo-postgresql').and_return(true)
  end

  context 'when geo postgres is enabled' do
    before do
      stub_gitlab_rb(geo_postgresql: { enable: true })
    end

    it 'includes the postgresql::bin recipe' do
      expect(chef_run).to include_recipe('postgresql::bin')
    end

    it 'includes the postgresql_user recipe' do
      expect(chef_run).to include_recipe('postgresql::user')
    end

    it 'includes the postgresql_sysctl recipe' do
      expect(chef_run).to include_recipe('postgresql::sysctl')
    end

    it 'does not warn the user that a restart is needed by default' do
      allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
      expect(chef_run).not_to run_ruby_block('warn pending geo-postgresql restart')
    end

    it 'notifies restarts postgresql when the postgresql runit run file changes' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('geo-postgresql').and_return(true)

      psql_service = chef_run.service('geo-postgresql')
      expect(psql_service).not_to subscribe_to('template[/opt/gitlab/sv/geo-postgresql/run]').on(:restart).delayed
    end

    it 'includes runtime.conf in postgresql.conf' do
      expect(chef_run).to render_file(postgresql_conf)
        .with_content(/include 'runtime.conf'/)
    end

    it 'creates the gitlab_geo role in the geo-postgresql database, without a password' do
      expect(chef_run).to create_postgresql_user('gitlab_geo').with(password: nil)
    end

    it 'creates gitlabhq_geo_production database' do
      params = {
        owner: 'gitlab_geo'
      }
      expect(chef_run).to create_postgresql_database('gitlabhq_geo_production').with(params)
    end

    context 'with default settings' do
      it_behaves_like 'enabled runit service', 'geo-postgresql', 'root', 'root'

      context 'when rendering postgresql.conf' do
        it 'correctly sets the shared_preload_libraries default setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['shared_preload_libraries']).to be_nil

          expect(chef_run).to render_file(postgresql_conf)
            .with_content(/shared_preload_libraries = ''/)
        end

        it 'sets archive settings' do
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/archive_mode = off/)
        end

        it 'sets the max_replication_slots setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['max_replication_slots']).to eq(0)

          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/max_replication_slots = 0/)
        end

        it 'sets the synchronous_commit setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['synchronous_standby_names']).to eq('')

          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/synchronous_standby_names = ''/)
        end

        it 'does not set dynamic_shared_memory_type by default' do
          expect(chef_run).not_to render_file(
            postgresql_conf
          ).with_content(/^dynamic_shared_memory_type = /)
        end

        it 'sets the max_locks_per_transaction setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['max_locks_per_transaction'])
            .to eq(128)

          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/max_locks_per_transaction = 128/)
        end
      end
      context 'when rendering runtime.conf' do
        it 'correctly sets the log_line_prefix default setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['log_line_prefix']).to be_nil

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/log_line_prefix = ''/)
        end

        it 'sets max_standby settings' do
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/max_standby_archive_delay = 30s/)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/max_standby_streaming_delay = 30s/)
        end

        it 'sets archive settings' do
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/archive_command = ''/)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/archive_timeout = 0/)
        end

        it 'sets the synchronous_commit setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['synchronous_commit']).to eq('on')

          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/synchronous_commit = on/)
        end

        it 'sets the hot_standby_feedback setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['hot_standby_feedback'])
            .to eq('off')

          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/hot_standby_feedback = off/)
        end

        it 'sets the random_page_cost setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['random_page_cost'])
            .to eq(2.0)

          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/random_page_cost = 2\.0/)
        end

        it 'sets the log_temp_files setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['log_temp_files'])
            .to eq(-1)

          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/log_temp_files = -1/)
        end

        it 'sets the log_checkpoints setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['log_checkpoints'])
            .to eq('off')

          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/log_checkpoints = off/)
        end

        it 'sets idle_in_transaction_session_timeout' do
          expect(chef_run.node['gitlab']['geo-postgresql']['idle_in_transaction_session_timeout'])
            .to eq('60000')

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/idle_in_transaction_session_timeout = 60000/)
        end

        it 'sets effective_io_concurrency' do
          expect(chef_run.node['gitlab']['geo-postgresql']['effective_io_concurrency'])
            .to eq(1)

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/effective_io_concurrency = 1/)
        end

        it 'sets max_worker_processes' do
          expect(chef_run.node['gitlab']['geo-postgresql']['max_worker_processes'])
            .to eq(8)

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/max_worker_processes = 8/)
        end

        it 'sets max_parallel_workers_per_gather' do
          expect(chef_run.node['gitlab']['geo-postgresql']['max_parallel_workers_per_gather'])
            .to eq(0)

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/max_parallel_workers_per_gather = 0/)
        end

        it 'sets log_lock_waits' do
          expect(chef_run.node['gitlab']['geo-postgresql']['log_lock_waits'])
            .to eq(1)

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/log_lock_waits = 1/)
        end

        it 'sets deadlock_timeout' do
          expect(chef_run.node['gitlab']['geo-postgresql']['deadlock_timeout'])
            .to eq('5s')

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/deadlock_timeout = '5s'/)
        end

        it 'sets track_io_timing' do
          expect(chef_run.node['gitlab']['geo-postgresql']['track_io_timing'])
            .to eq('off')

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/track_io_timing = 'off'/)
        end
      end
    end

    context 'with user specified settings' do
      before do
        stub_gitlab_rb(geo_postgresql: {
                         enable: true,
                         dynamic_shared_memory_type: 'none',
                         custom_pg_hba_entries: {
                           foo: [
                             type: 'host',
                             database: 'foo',
                             user: 'bar',
                             cidr: '127.0.0.1/32',
                             method: 'trust'
                           ]
                         },
                         sql_user_password: 'fakepasswordhash',
                         shared_preload_libraries: 'pg_stat_statements',
                         log_line_prefix: '%a',
                         max_standby_archive_delay: '60s',
                         max_standby_streaming_delay: '120s',
                         archive_mode: 'on',
                         archive_command: 'command',
                         archive_timeout: '120',
                       },
                       postgresql: {
                         username: 'foo',
                         group: 'bar'
                       }
                      )
      end

      it 'notifies geo-postgresql reload' do
        runtime_resource = chef_run.template(runtime_conf)
        expect(runtime_resource).to notify('execute[reload geo-postgresql]').to(:run).immediately
      end

      it 'creates the gitlab_geo role in the geo-postgresql database with the specified password' do
        expect(chef_run).to create_postgresql_user('gitlab_geo').with(password: 'md5fakepasswordhash')
      end

      context 'when rendering postgresql.conf' do
        it 'sets the dynamic_shared_memory_type' do
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/^dynamic_shared_memory_type = none/)
        end

        it 'correctly sets the shared_preload_libraries setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['shared_preload_libraries']).to eql('pg_stat_statements')

          expect(chef_run).to render_file(postgresql_conf)
            .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
        end

        it 'sets archive settings' do
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/archive_mode = on/)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/archive_command = 'command'/)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/archive_timeout = 120/)
        end
      end

      context 'when rendering runtime.conf' do
        it 'correctly sets the log_line_prefix setting' do
          expect(chef_run.node['gitlab']['geo-postgresql']['log_line_prefix']).to eql('%a')

          expect(chef_run).to render_file(runtime_conf)
            .with_content(/log_line_prefix = '%a'/)
        end

        it 'sets max_standby settings' do
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/max_standby_archive_delay = 60s/)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/max_standby_streaming_delay = 120s/)
        end

        context 'when rendering pg_hba.conf' do
          it 'creates a standard pg_hba.conf' do
            expect(chef_run).to render_file(pg_hba_conf)
              .with_content('local   all         all                               peer map=gitlab')
          end

          it 'adds users custom entries to pg_hba.conf' do
            expect(chef_run).to render_file(pg_hba_conf)
              .with_content('host foo bar 127.0.0.1/32 trust')
          end
        end
      end
    end

    context 'when geo postgres is disabled' do
      before do
        stub_gitlab_rb(geo_postgresql: { enable: false })
      end

      it_behaves_like 'disabled runit service', 'geo-postgresql'
    end
  end
end

RSpec.describe 'geo postgresql when version mismatches occur' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:postgresql_conf) { '/var/opt/gitlab/geo-postgresql/data/postgresql.conf' }
  let(:runtime_conf) { '/var/opt/gitlab/geo-postgresql/data/runtime.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(geo_postgresql: { enable: true })
  end

  context 'running version differs from installed version' do
    before do
      allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('reality'))
    end

    it 'warns the user that a restart is needed' do
      allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
      expect(chef_run).to run_ruby_block('warn pending geo-postgresql restart')
    end

    it 'does not warns the user that a restart is needed when geo-postgres is stopped' do
      expect(chef_run).not_to run_ruby_block('warn pending geo-postgresql restart')
    end
  end

  context 'running version differs from data version' do
    before do
      allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return(PGVersion.new('reality'))
    end

    it 'does not warn the user that a restart is needed' do
      allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
      expect(chef_run).not_to run_ruby_block('warn pending geo-postgresql restart')
    end
  end
end
