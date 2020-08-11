require 'chef_helper'

RSpec.describe 'geo postgresql 9.2' do
  let(:postgresql_conf) { '/var/opt/gitlab/geo-postgresql/data/postgresql.conf' }
  let(:runtime_conf) { '/var/opt/gitlab/geo-postgresql/data/runtime.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('9.2.18'))
    allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('9.2.18'))
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return(PGVersion.new('9.2'))

    # Workaround for Chef reloading instances across different examples
    allow_any_instance_of(GeoPgHelper).to receive(:bootstrapped?).and_return(true)
    allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
    allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('geo-postgresql').and_return(true)
  end

  context 'when geo postgres is disabled' do
    let(:chef_run) do
      stub_gitlab_rb(geo_postgresql: { enable: false })

      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it_behaves_like 'disabled runit service', 'geo-postgresql'
  end

  context 'with default settings' do
    let(:chef_run) do
      stub_gitlab_rb(geo_postgresql: { enable: true })

      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
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

    context 'running version differs from installed version' do
      before do
        allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('9.6.8'))
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
        allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('9.2.18'))
        allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('9.2.18'))
      end

      it 'does not warn the user that a restart is needed' do
        allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
        expect(chef_run).not_to run_ruby_block('warn pending geo-postgresql restart')
      end
    end
  end

  context 'with default cached settings' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(geo_postgresql: { enable: true })
      end

      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it_behaves_like 'enabled runit service', 'geo-postgresql', 'root', 'root'

    it 'includes the postgresql::bin recipe' do
      expect(chef_run).to include_recipe('postgresql::bin')
    end

    it 'includes the postgresql_user recipe' do
      expect(chef_run).to include_recipe('postgresql::user')
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

    context 'renders postgresql.conf' do
      it 'includes runtime.conf in postgresql.conf' do
        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/include 'runtime.conf'/)
      end

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

      context 'version specific settings' do
        it 'sets unix_socket_directory' do
          expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directory']).to eq('/var/opt/gitlab/geo-postgresql')
          expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directories']).to eq(nil)
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content { |content|
            expect(content).to match(
              /unix_socket_directory = '\/var\/opt\/gitlab\/geo-postgresql'/
            )
            expect(content).not_to match(
              /unix_socket_directories = '\/var\/opt\/gitlab\/geo-postgresql'/
            )
          }
        end

        it 'does not set the max_replication_slots setting' do
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content { |content|
            expect(content).not_to match(/max_replication_slots = /)
          }
        end
      end
    end

    context 'renders runtime.conf' do
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

      context 'version specific settings' do
        it 'sets checkpoint_segments' do
          expect(chef_run.node['gitlab']['geo-postgresql']['checkpoint_segments']).to eq(10)
          expect(chef_run).to render_file(
            runtime_conf
          ).with_content(/checkpoint_segments = 10/)
        end
      end
    end

    it 'does not create foreign table mapping' do
      expect(chef_run).not_to create_postgresql_schema('gitlab_secondary')
      expect(chef_run).not_to create_postgresql_fdw('gitlab_secondary')
      expect(chef_run).not_to create_postgresql_fdw_user_mapping('gitlab_secondary')
      expect(chef_run).not_to run_execute('refresh foreign table definition')
    end
  end

  context 'when a SQL user password is set' do
    let(:chef_run) do
      stub_gitlab_rb(
        geo_postgresql: {
          enable: true,
          sql_user_password: 'fakepasswordhash',
        }
      )

      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it 'creates the gitlab_geo role in the geo-postgresql database with the specified password' do
      expect(chef_run).to create_postgresql_user('gitlab_geo').with(password: 'md5fakepasswordhash')
    end
  end

  context 'when user settings are set' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(geo_postgresql: {
                         enable: true,
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
                       })
      end

      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it_behaves_like 'enabled runit service', 'geo-postgresql', 'root', 'root'

    it 'correctly sets the shared_preload_libraries setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['shared_preload_libraries']).to eql('pg_stat_statements')

      expect(chef_run).to render_file(postgresql_conf)
        .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
    end

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

    it 'notifies geo-postgresql reload' do
      runtime_resource = chef_run.template(runtime_conf)
      expect(runtime_resource).to notify('execute[reload geo-postgresql]').to(:run).immediately
    end
  end
end

RSpec.describe 'geo postgresql 9.6' do
  let(:postgresql_conf) { '/var/opt/gitlab/geo-postgresql/data/postgresql.conf' }
  let(:runtime_conf) { '/var/opt/gitlab/geo-postgresql/data/runtime.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(GeoPgHelper).to receive(:version).and_return(PGVersion.new('9.6.1'))
    allow_any_instance_of(GeoPgHelper).to receive(:running_version).and_return(PGVersion.new('9.6.1'))
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return(PGVersion.new('9.6'))
  end

  cached(:chef_run) do
    RSpec::Mocks.with_temporary_scope do
      stub_gitlab_rb(
        geo_postgresql: {
          enable: true,
          custom_pg_hba_entries: {
            foo: [
              type: 'host',
              database: 'foo',
              user: 'bar',
              cidr: '127.0.0.1/32',
              method: 'trust'
            ]
          }
        }
      )
    end

    ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
  end

  context 'version specific settings' do
    it 'sets unix_socket_directories' do
      expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directory']).to eq('/var/opt/gitlab/geo-postgresql')
      expect(chef_run).to render_file(
        postgresql_conf
      ).with_content { |content|
        expect(content).to match(
          /unix_socket_directories = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
        expect(content).not_to match(
          /unix_socket_directory = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
      }
    end

    context 'renders postgresql.conf' do
      it 'does not set checkpoint_segments' do
        expect(chef_run).not_to render_file(
          postgresql_conf
        ).with_content(/checkpoint_segments = 10/)
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

      context 'when dynamic_shared_memory_type is none' do
        let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

        before do
          stub_gitlab_rb(
            geo_postgresql: {
              enable: true,
              dynamic_shared_memory_type: 'none'
            }
          )
        end

        it 'sets the dynamic_shared_memory_type' do
          expect(chef_run).to render_file(
            postgresql_conf
          ).with_content(/^dynamic_shared_memory_type = none/)
        end
      end
    end

    context 'renders runtime.conf' do
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

  context 'pg_hba.conf' do
    let(:pg_hba_conf) { '/var/opt/gitlab/geo-postgresql/data/pg_hba.conf' }

    it 'creates a standard pg_hba.conf' do
      expect(chef_run).to render_file(pg_hba_conf)
        .with_content('local   all         all                               peer map=gitlab')
    end

    it 'adds users custom entries to pg_hba.conf' do
      expect(chef_run).to render_file(pg_hba_conf)
        .with_content('host foo bar 127.0.0.1/32 trust')
    end
  end

  context 'FDW is disabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(
          geo_postgresql: {
            enable: true,
            sql_user: 'mygeodbuser'
          },
          geo_secondary: {
            db_database: 'gitlab_geodb',
            db_fdw: false
          },
          gitlab_rails: {
            db_host: '10.0.0.1',
            db_port: 5430,
            db_username: 'mydbuser',
            db_database: 'gitlab_myorg',
            db_password: 'custompass'
          }
        )
      end

      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it 'does not setup foreign table mapping' do
      expect(chef_run).not_to create_postgresql_schema('gitlab_secondary')
      expect(chef_run).not_to create_postgresql_fdw('gitlab_secondary')
      expect(chef_run).not_to create_postgresql_fdw_user_mapping('gitlab_secondary')
      expect(chef_run).not_to run_execute('refresh foreign table definition')
    end
  end

  context 'FDW support' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(
          geo_postgresql: {
            enable: true,
            sql_user: 'mygeodbuser'
          },
          geo_secondary: {
            db_database: 'gitlab_geodb'
          },
          gitlab_rails: {
            db_host: '10.0.0.1',
            db_port: 5430,
            db_username: 'mydbuser',
            db_database: 'gitlab_myorg',
            db_password: 'custompass'
          }
        )
      end

      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(GeoPgHelper).to receive(:is_running?).and_return(true)
      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
    end

    it 'creates gitlab_secondary schema' do
      params = {
        schema: 'gitlab_secondary',
        database: 'gitlab_geodb',
        owner: 'mygeodbuser'
      }
      expect(chef_run).to create_postgresql_schema('gitlab_secondary').with(params)
    end

    it 'creates a postgresql fdw connection in the geo-postgresql database' do
      params = {
        db_name: 'gitlab_geodb',
        external_host: '10.0.0.1',
        external_port: 5430,
        external_name: 'gitlab_myorg'
      }

      expect(chef_run).to create_postgresql_fdw('gitlab_secondary').with(params)
    end

    it 'creates a postgresql fdw user mapping in the geo-postgresql database' do
      params = {
        db_user: 'mygeodbuser',
        db_name: 'gitlab_geodb',
        external_user: 'mydbuser',
        external_password: 'custompass'
      }
      expect(chef_run).to create_postgresql_fdw_user_mapping('gitlab_secondary').with(params)
    end

    context 'when a custom external FDW user is used' do
      let(:chef_run) do
        stub_gitlab_rb(
          geo_postgresql: {
            enable: true,
            sql_user: 'mygeodbuser',
            fdw_external_user: 'fdw_user',
            fdw_external_password: 'my-fdw-password'
          },
          geo_secondary: {
            db_database: 'gitlab_geodb',
          }
        )

        ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
      end

      it 'creates a mapping with custom external user' do
        params = {
          db_user: 'mygeodbuser',
          db_name: 'gitlab_geodb',
          external_user: 'fdw_user',
          external_password: 'my-fdw-password'
        }
        expect(chef_run).to create_postgresql_fdw_user_mapping('gitlab_secondary').with(params)
      end
    end

    context 'when secondary database is not managed' do
      before do
        stub_gitlab_rb(
          geo_postgresql: {
            enable: true,
            sql_user: 'mygeodbuser'
          },
          geo_secondary: {
            db_database: 'gitlab_geodb',
            db_fdw: true
          },
          gitlab_rails: {
            db_host: '10.0.0.10',
            db_port: 5430,
            db_username: 'mydbuser',
            db_database: 'gitlab_myorg',
            db_password: 'custompass'
          }
        )
      end

      let(:chef_run) do
        allow_any_instance_of(GeoPgHelper).to receive(:is_offline_or_readonly?).and_return(false)
        allow_any_instance_of(GeoPgHelper).to receive(:schema_exists?).and_return(true)
        allow_any_instance_of(GitlabGeoHelper).to receive(:geo_database_configured?).and_return(true)

        # not managed (using external database)
        allow_any_instance_of(PgHelper).to receive(:is_managed_and_offline?).and_return(false)

        ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default')
      end

      it 'creates foreign table mapping' do
        expect(chef_run).to create_postgresql_schema('gitlab_secondary')
        expect(chef_run).to create_postgresql_fdw('gitlab_secondary')
        expect(chef_run).to create_postgresql_fdw_user_mapping('gitlab_secondary')
      end
    end
  end
end
