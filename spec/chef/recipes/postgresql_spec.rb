require 'chef_helper'

RSpec.describe 'postgresql 9.2' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }
  let(:postgresql_data_dir) { '/var/opt/gitlab/postgresql/data' }
  let(:postgresql_ssl_cert) { File.join(postgresql_data_dir, 'server.crt') }
  let(:postgresql_ssl_key) { File.join(postgresql_data_dir, 'server.key') }
  let(:postgresql_conf) { File.join(postgresql_data_dir, 'postgresql.conf') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }
  let(:gitlab_psql_rc) do
    <<-EOF
psql_user='gitlab-psql'
psql_group='gitlab-psql'
psql_host='/var/opt/gitlab/postgresql'
psql_port='5432'
    EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('9.2.18'))
    allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('9.2.18'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('9.2'))
  end

  it 'includes the postgresql::bin recipe' do
    expect(chef_run).to include_recipe('postgresql::bin')
  end

  it 'includes the postgresql::user recipe' do
    expect(chef_run).to include_recipe('postgresql::user')
  end

  it 'creates gitlab-psql-rc' do
    expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-psql-rc')
      .with_content(gitlab_psql_rc)
  end

  it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'gitlab-psql', 'gitlab-psql'

  context 'renders postgresql.conf' do
    it 'includes runtime.conf in postgresql.conf' do
      expect(chef_run).to render_file(postgresql_conf)
        .with_content(/include 'runtime.conf'/)
    end

    context 'with default settings' do
      it 'correctly sets the shared_preload_libraries default setting' do
        expect(chef_run.node['postgresql']['shared_preload_libraries'])
          .to be_nil

        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/shared_preload_libraries = ''/)
      end

      it 'sets archive settings' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/archive_mode = off/)
      end
    end

    context 'when user settings are set' do
      before do
        stub_gitlab_rb(postgresql: {
                         shared_preload_libraries: 'pg_stat_statements',
                         archive_mode: 'on',
                         username: 'foo',
                         group: 'bar'
                       })
      end

      it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'foo', 'bar'

      it 'correctly sets the shared_preload_libraries setting' do
        expect(chef_run.node['postgresql']['shared_preload_libraries'])
          .to eql('pg_stat_statements')

        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
      end

      it 'sets archive settings' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/archive_mode = on/)
      end
    end

    context 'sets SSL settings' do
      it 'enables SSL by default' do
        expect(chef_run.node['postgresql']['ssl'])
          .to eq('on')

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl = on/)
      end

      it 'generates a self-signed certificate and key' do
        stub_gitlab_rb(postgresql: { ssl_cert_file: 'certfile', ssl_key_file: 'keyfile' })

        absolute_cert_path = File.join(postgresql_data_dir, 'certfile')
        absolute_key_path = File.join(postgresql_data_dir, 'keyfile')

        expect(chef_run).to create_file(absolute_cert_path).with(
          user: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: 0400
        )

        expect(chef_run).to create_file(absolute_key_path).with(
          user: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: 0400
        )

        expect(chef_run).to render_file(absolute_cert_path)
          .with_content(/-----BEGIN CERTIFICATE-----/)
        expect(chef_run).to render_file(absolute_key_path)
          .with_content(/-----BEGIN RSA PRIVATE KEY-----/)
      end

      it 'disables SSL' do
        stub_gitlab_rb(postgresql: { ssl: 'off' })

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl = off/)

        expect(chef_run).not_to render_file(postgresql_ssl_cert)
        expect(chef_run).not_to render_file(postgresql_ssl_key)
      end

      it 'activates SSL' do
        stub_gitlab_rb(postgresql: { ssl_crl_file: 'revoke.crl' })

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl = on/)
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(%r{ssl_ciphers = 'HIGH:MEDIUM:\+3DES:!aNULL:!SSLv3:!TLSv1'})
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_cert_file = 'server.crt'/)
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_key_file = 'server.key'/)
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(%r{ssl_ca_file = '/opt/gitlab/embedded/ssl/certs/cacert.pem'})
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_crl_file = 'revoke.crl'/)
      end

      it 'sets SSL ciphers' do
        stub_gitlab_rb(postgresql: { ssl_ciphers: 'ALL' })

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_ciphers = 'ALL'/)
      end
    end
  end

  context 'renders runtime.conf' do
    context 'with default settings' do
      it 'correctly sets the log_line_prefix default setting' do
        expect(chef_run.node['postgresql']['log_line_prefix'])
          .to be_nil

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/log_line_prefix = ''/)
      end

      it 'does not include log_statement by default' do
        expect(chef_run).not_to render_file(runtime_conf)
          .with_content(/log_statement = /)
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
    end

    context 'when user settings are set' do
      before do
        stub_gitlab_rb(postgresql: {
                         log_line_prefix: '%a',
                         log_statement: 'all',
                         max_standby_archive_delay: '60s',
                         max_standby_streaming_delay: '120s',
                         archive_command: 'command',
                         archive_timeout: '120',
                       })
      end

      it 'correctly sets the log_line_prefix setting' do
        expect(chef_run.node['postgresql']['log_line_prefix'])
          .to eql('%a')

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/log_line_prefix = '%a'/)
      end

      it 'correctly sets the log_line_prefix setting' do
        expect(chef_run.node['postgresql']['log_statement'])
          .to eql('all')

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/log_statement = 'all'/)
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
          runtime_conf
        ).with_content(/archive_command = 'command'/)
        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/archive_timeout = 120/)
      end
    end
  end

  context 'version specific settings' do
    it 'sets unix_socket_directory' do
      expect(chef_run.node['postgresql']['unix_socket_directory'])
        .to eq('/var/opt/gitlab/postgresql')
      expect(chef_run.node['postgresql']['unix_socket_directories'])
        .to eq(nil)
      expect(chef_run).to render_file(
        postgresql_conf
      ).with_content { |content|
        expect(content).to match(
          /unix_socket_directory = '\/var\/opt\/gitlab\/postgresql'/
        )
        expect(content).not_to match(
          /unix_socket_directories = '\/var\/opt\/gitlab\/postgresql'/
        )
      }
    end

    it 'sets checkpoint_segments' do
      expect(chef_run.node['postgresql']['checkpoint_segments'])
        .to eq(10)
      expect(chef_run).to render_file(
        runtime_conf
      ).with_content(/checkpoint_segments = 10/)
    end

    it 'does not set the max_replication_slots setting' do
      expect(chef_run).to render_file(
        postgresql_conf
      ).with_content { |content|
        expect(content).not_to match(/max_replication_slots = /)
      }
    end

    context 'running version differs from data version' do
      before do
        allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('9.6.1'))
        allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('9.6.1'))
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2*").and_return(
          ['/opt/gitlab/embedded/postgresql/9.2']
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/9.2/bin/foo_one
            /opt/gitlab/embedded/postgresql/9.2/bin/foo_two
            /opt/gitlab/embedded/postgresql/9.2/bin/foo_three
          )
        )
      end

      it 'corrects symlinks to the correct location' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/9.2/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end

      it 'does not warn the user that a restart is needed' do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
        expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
      end
    end
  end
end

RSpec.describe 'postgresql 9.6' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config database_objects)).converge('gitlab::default') }
  let(:postgresql_conf) { '/var/opt/gitlab/postgresql/data/postgresql.conf' }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('9.6.1'))
    allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('9.6.1'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('9.6'))
  end

  it 'does not warn the user that a restart is needed by default' do
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
  end

  context 'version specific settings' do
    it 'sets unix_socket_directories' do
      expect(chef_run.node['postgresql']['unix_socket_directory'])
        .to eq('/var/opt/gitlab/postgresql')
      expect(chef_run).to render_file(
        postgresql_conf
      ).with_content { |content|
        expect(content).to match(
          /unix_socket_directories = '\/var\/opt\/gitlab\/postgresql'/
        )
        expect(content).not_to match(
          /unix_socket_directory = '\/var\/opt\/gitlab\/postgresql'/
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
        expect(chef_run.node['postgresql']['max_replication_slots'])
          .to eq(0)

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/max_replication_slots = 0/)
      end

      it 'sets the synchronous_commit setting' do
        expect(chef_run.node['postgresql']['synchronous_standby_names'])
          .to eq('')

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/synchronous_standby_names = ''/)
      end

      it 'does not set dynamic_shared_memory_type by default' do
        expect(chef_run).not_to render_file(
          postgresql_conf
        ).with_content(/^dynamic_shared_memory_type = /)
      end

      it 'sets logging directory' do
        expect(chef_run.node['postgresql']['log_directory'])
          .to eq('/var/log/gitlab/postgresql')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(%r(^log_directory = '/var/log/gitlab/postgresql'))
      end

      it 'sets the max_locks_per_transaction setting' do
        expect(chef_run.node['postgresql']['max_locks_per_transaction'])
          .to eq(128)

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/max_locks_per_transaction = 128/)
      end

      context 'with geo_secondary_role enabled' do
        before { stub_gitlab_rb(geo_secondary_role: { enable: true }) }

        it 'includes gitlab-geo.conf in postgresql.conf' do
          expect(chef_run).to render_file(postgresql_conf)
            .with_content(/include_if_exists 'gitlab-geo.conf'/)
        end
      end

      context 'with geo_secondary_role disabled' do
        before { stub_gitlab_rb(geo_secondary_role: { enable: false }) }

        it 'does not gitlab-geo.conf in postgresql.conf' do
          expect(chef_run).to render_file(postgresql_conf)
            .with_content { |content|
              expect(content).not_to match('gitlab-geo.conf')
            }
        end
      end

      context 'with custom logging settings set' do
        before do
          stub_gitlab_rb({
                           postgresql: {
                             log_destination: 'csvlog',
                             logging_collector: 'on',
                             log_filename: 'test.log',
                             log_file_mode: '0600',
                             log_truncate_on_rotation: 'on',
                             log_rotation_age: '1d',
                             log_rotation_size: '10MB'
                           }
                         })
        end

        it 'sets logging parameters' do
          expect(chef_run).to render_file(postgresql_conf).with_content { |content|
                                expect(content).to match(/logging_collector = on/)
                              }

          expect(chef_run).to render_file(runtime_conf).with_content { |content|
            expect(content).to match(/log_destination = 'csvlog'/)
            expect(content).to match(/log_filename = 'test.log'/)
            expect(content).to match(/log_file_mode = 0600/)
            expect(content).to match(/log_truncate_on_rotation = on/)
            expect(content).to match(/log_rotation_age = 1d/)
            expect(content).to match(/log_rotation_size = 10MB/)
          }
        end
      end

      context 'when dynamic_shared_memory_type is none' do
        before do
          stub_gitlab_rb({
                           postgresql: {
                             dynamic_shared_memory_type: 'none'
                           }
                         })
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
        expect(chef_run.node['postgresql']['synchronous_commit'])
          .to eq('on')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/synchronous_commit = on/)
      end

      it 'sets the hot_standby_feedback setting' do
        expect(chef_run.node['postgresql']['hot_standby_feedback'])
          .to eq('off')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/hot_standby_feedback = off/)
      end

      it 'sets the random_page_cost setting' do
        expect(chef_run.node['postgresql']['random_page_cost'])
          .to eq(2.0)

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/random_page_cost = 2\.0/)
      end

      it 'sets the log_temp_files setting' do
        expect(chef_run.node['postgresql']['log_temp_files'])
          .to eq(-1)

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/log_temp_files = -1/)
      end

      it 'sets the log_checkpoints setting' do
        expect(chef_run.node['postgresql']['log_checkpoints'])
          .to eq('off')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/log_checkpoints = off/)
      end

      it 'sets idle_in_transaction_session_timeout' do
        expect(chef_run.node['postgresql']['idle_in_transaction_session_timeout'])
          .to eq('60000')

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/idle_in_transaction_session_timeout = 60000/)
      end

      it 'sets effective_io_concurrency' do
        expect(chef_run.node['postgresql']['effective_io_concurrency'])
          .to eq(1)

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/effective_io_concurrency = 1/)
      end

      it 'sets max_worker_processes' do
        expect(chef_run.node['postgresql']['max_worker_processes'])
          .to eq(8)

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/max_worker_processes = 8/)
      end

      it 'sets max_parallel_workers_per_gather' do
        expect(chef_run.node['postgresql']['max_parallel_workers_per_gather'])
          .to eq(0)

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/max_parallel_workers_per_gather = 0/)
      end

      it 'sets log_lock_waits' do
        expect(chef_run.node['postgresql']['log_lock_waits'])
          .to eq(1)

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/log_lock_waits = 1/)
      end

      it 'sets deadlock_timeout' do
        expect(chef_run.node['postgresql']['deadlock_timeout'])
          .to eq('5s')

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/deadlock_timeout = '5s'/)
      end

      it 'sets track_io_timing' do
        expect(chef_run.node['postgresql']['track_io_timing'])
          .to eq('off')

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/track_io_timing = 'off'/)
      end

      it 'sets default_statistics_target' do
        expect(chef_run.node['postgresql']['default_statistics_target'])
          .to eq(1000)

        expect(chef_run).to render_file(runtime_conf)
          .with_content(/default_statistics_target = 1000/)
      end
    end

    it 'notifies reload postgresql when postgresql.conf changes' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('postgresql').and_return(true)
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).with('postgresql').and_return(true)
      expect(chef_run).to create_postgresql_config('gitlab')
      postgresql_config = chef_run.postgresql_config('gitlab')
      expect(postgresql_config).to notify('execute[reload postgresql]').to(:run).immediately
      expect(postgresql_config).to notify('execute[start postgresql]').to(:run).immediately
    end

    it 'notifies restarts postgresql when the postgresql runit run file changes' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('postgresql').and_return(true)

      psql_service = chef_run.service('postgresql')
      expect(psql_service).not_to subscribe_to('template[/opt/gitlab/sv/postgresql/run]').on(:restart).delayed
    end

    it 'creates the pg_trgm extension when it is possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('pg_trgm', 'gitlabhq_production').and_return(true)
      expect(chef_run).to enable_postgresql_extension('pg_trgm')
    end

    it 'does not create the pg_trgm extension if it is not possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('pg_trgm', 'gitlabhq_production').and_return(false)
      expect(chef_run).not_to run_execute('enable pg_trgm extension')
    end

    it 'creates the btree_gist extension when it is possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('btree_gist', 'gitlabhq_production').and_return(true)
      expect(chef_run).to enable_postgresql_extension('btree_gist')
    end

    it 'does not create the btree_gist extension if it is not possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('btree_gist', 'gitlabhq_production').and_return(false)
      expect(chef_run).not_to run_execute('enable btree_gist extension')
    end

    context 'running version differs from installed version' do
      before do
        allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('9.2.18'))
      end

      it 'warns the user that a restart is needed' do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
        expect(chef_run).to run_ruby_block('warn pending postgresql restart')
      end

      it 'does not warns the user that a restart is needed when postgres is stopped' do
        expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
      end
    end

    context 'running version differs from data version' do
      before do
        allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('9.2.18'))
        allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('9.2.18'))
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6*").and_return(
          ['/opt/gitlab/embedded/postgresql/9.6']
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_one
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_two
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_three
          )
        )
      end

      it 'corrects symlinks to the correct location' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/9.6/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end

      it 'does not warn the user that a restart is needed' do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
        expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
      end
    end

    context 'old unused data version is present' do
      before do
        allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('9.2'))
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2*").and_return([])
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6*").and_return(
          ['/opt/gitlab/embedded/postgresql/9.6']
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_one
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_two
            /opt/gitlab/embedded/postgresql/9.6/bin/foo_three
          )
        )
      end

      it 'corrects symlinks to the correct location' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/9.6/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end
    end

    context 'the desired postgres version is missing' do
      before do
        allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('9.2.18'))
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2*").and_return([])
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6*").and_return([])
      end

      it 'throws an error' do
        expect do
          chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
        end.to raise_error(RuntimeError, /Could not find PostgreSQL binaries/)
      end
    end
  end

  context 'postgresql_user resource' do
    before do
      stub_gitlab_rb(
        {
          postgresql: {
            sql_user_password: 'fakepassword',
            sql_replication_password: 'fakepassword'
          }
        }
      )

      allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(false)
    end

    it 'should set a password for sql_user when sql_user_password is set' do
      expect(chef_run).to create_postgresql_user('gitlab').with(password: 'md5fakepassword')
    end

    it 'should create the gitlab_replicator user with replication permissions' do
      expect(chef_run).to create_postgresql_user('gitlab_replicator').with(
        options: %w(replication),
        password: 'md5fakepassword'
      )
    end

    context 'when database is a secondary' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(true)
        allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
      end

      it 'should not create users' do
        expect(chef_run).not_to create_postgresql_user('gitlab')
        expect(chef_run).not_to create_postgresql_user('gitlab_replicator')
      end

      it 'should not activate pg_trgm' do
        expect(chef_run).not_to run_execute('enable pg_trgm extension')
      end
    end
  end

  context 'pg_hba.conf' do
    let(:pg_hba_conf) { '/var/opt/gitlab/postgresql/data/pg_hba.conf' }
    it 'creates a standard pg_hba.conf' do
      expect(chef_run).to render_file(pg_hba_conf)
        .with_content('local   all         all                               peer map=gitlab')
    end

    it 'prefers hostssl when configured in pg_hba.conf' do
      stub_gitlab_rb(
        postgresql: {
          hostssl: true,
          trust_auth_cidr_addresses: ['127.0.0.1/32']
        }
      )
      expect(chef_run).to render_file(pg_hba_conf)
        .with_content('hostssl    all         all         127.0.0.1/32           trust')
    end

    it 'adds users custom entries to pg_hba.conf' do
      stub_gitlab_rb(
        postgresql: {
          custom_pg_hba_entries: {
            foo: [
              {
                type: 'host',
                database: 'foo',
                user: 'bar',
                cidr: '127.0.0.1/32',
                method: 'trust'
              }
            ]
          }
        }
      )
      expect(chef_run).to render_file(pg_hba_conf)
        .with_content('host foo bar 127.0.0.1/32 trust')
    end

    it 'notifies postgresql reload' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('postgresql').and_return(true)
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).with('postgresql').and_return(true)
      postgresql_config = chef_run.postgresql_config('gitlab')
      expect(postgresql_config).to notify('execute[reload postgresql]').to(:run).immediately
      expect(postgresql_config).to notify('execute[start postgresql]').to(:run).immediately
    end
  end

  it 'creates sysctl files' do
    expect(chef_run).to create_gitlab_sysctl('kernel.shmmax').with_value(17179869184)
  end
end

RSpec.describe 'postgresql::bin' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab). to receive(:[]).and_call_original
  end

  context 'when bundled postgresql is disabled' do
    before do
      stub_gitlab_rb(
        postgresql: {
          enable: false
        }
      )

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/PG_VERSION').and_return(false)

      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(nil)
      version = double("PgHelper", major: 10, minor: 9)
      allow_any_instance_of(PgHelper).to receive(:version).and_return(version)
    end

    it 'still includes the postgresql::bin recipe' do
      expect(chef_run).to include_recipe('postgresql::bin')
    end

    # We do expect the ruby block to run, but nothing to be found
    it "doesn't link any files by default" do
      expect(FileUtils).to_not receive(:ln_sf)
    end

    context "with postgresql['version'] set" do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false,
            version: '999'
          }
        )
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/999*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/999
          )
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/999/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/999/bin/foo_one
            /opt/gitlab/embedded/postgresql/999/bin/foo_two
            /opt/gitlab/embedded/postgresql/999/bin/foo_three
          )
        )
      end

      it "doesn't print a warning with a valid postgresql version" do
        expect(chef_run).to_not run_ruby_block('check_postgresql_version')
      end

      it 'links the specified version' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/999/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end
    end

    context "with an invalid version in postgresql['version']" do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false,
            version: '888'
          }
        )
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('/opt/gitlab/embedded/postgresql/888*').and_return([])
      end

      it 'should print a warning' do
        expect(chef_run).to run_ruby_block('check_postgresql_version')
      end
    end
  end
end

RSpec.describe 'postgresql dir and homedir' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when using default values for directories' do
    it 'creates necessary directories' do
      expect(chef_run).to create_directory('/var/opt/gitlab/postgresql').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
    end
  end

  context 'when using custom values for directories' do
    before do
      stub_gitlab_rb(postgresql: {
                       dir: '/mypgdir',
                       home: '/mypghomedir'
                     })
    end

    it 'creates necessary directories' do
      expect(chef_run).to create_directory('/mypgdir').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
      expect(chef_run).to create_directory('/mypghomedir').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
    end
  end
end
