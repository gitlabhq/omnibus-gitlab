require 'chef_helper'

RSpec.describe 'postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config database_objects)).converge('gitlab::default') }
  let(:postgresql_data_dir) { '/var/opt/gitlab/postgresql/data' }
  let(:postgresql_ssl_cert) { File.join(postgresql_data_dir, 'server.crt') }
  let(:postgresql_ssl_key) { File.join(postgresql_data_dir, 'server.key') }
  let(:postgresql_conf) { File.join(postgresql_data_dir, 'postgresql.conf') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }
  let(:pg_hba_conf) { '/var/opt/gitlab/postgresql/data/pg_hba.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('best_version'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('best_version'))
    allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('best_version'))
  end

  it 'includes the postgresql::bin recipe' do
    expect(chef_run).to include_recipe('postgresql::bin')
  end

  it 'includes the postgresql::user recipe' do
    expect(chef_run).to include_recipe('postgresql::user')
  end

  it 'includes postgresql::sysctl recipe' do
    expect(chef_run).to include_recipe('postgresql::sysctl')
  end

  it 'does not warn the user that a restart is needed by default' do
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
  end

  it 'includes runtime.conf in postgresql.conf' do
    expect(chef_run).to render_file(postgresql_conf)
      .with_content(/include 'runtime.conf'/)
  end

  context 'with default settings' do
    it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'gitlab-psql', 'gitlab-psql'

    context 'when rendering postgresql.conf' do
      it 'correctly sets the shared_preload_libraries default setting' do
        expect(chef_run.node['postgresql']['shared_preload_libraries'])
          .to be_nil

        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/shared_preload_libraries = ''/)
      end

      it 'disables archive mode' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/archive_mode = off/)
      end

      it 'enables SSL by default' do
        expect(chef_run.node['postgresql']['ssl'])
          .to eq('on')

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl = on/)
      end

      it 'sets the default SSL cipher list' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(%r{ssl_ciphers = 'HIGH:MEDIUM:\+3DES:!aNULL:!SSLv3:!TLSv1'})
      end

      it 'sets the default locations of SSL certificates' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_cert_file = 'server.crt'/)
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_key_file = 'server.key'/)
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(%r{ssl_ca_file = '/opt/gitlab/embedded/ssl/certs/cacert.pem'})
      end

      it 'leaves synchronous_standby_names empty' do
        expect(chef_run.node['postgresql']['synchronous_standby_names'])
          .to eq('')

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/synchronous_standby_names = ''/)
      end

      it 'disables wal_log_hints setting' do
        expect(chef_run.node['postgresql']['wal_log_hints']).to eq('off')

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/wal_log_hints = off/)
      end

      it 'does not set dynamic_shared_memory_type by default' do
        expect(chef_run).not_to render_file(
          postgresql_conf
        ).with_content(/^dynamic_shared_memory_type = /)
      end

      it 'sets the max_locks_per_transaction setting' do
        expect(chef_run.node['postgresql']['max_locks_per_transaction'])
          .to eq(128)

        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/max_locks_per_transaction = 128/)
      end

      it 'does not include gitlab-geo.conf' do
        expect(chef_run).to render_file(postgresql_conf)
          .with_content { |content|
            expect(content).not_to match(/include_if_exists 'gitlab-geo.conf'/)
          }
      end
    end

    it 'generates a self-signed SSL certificate and key' do
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

    context 'when rendering runtime.conf' do
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

      it 'sets logging directory' do
        expect(chef_run.node['postgresql']['log_directory'])
          .to eq('/var/log/gitlab/postgresql')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(%r(^log_directory = '/var/log/gitlab/postgresql'))
      end

      it 'disables hot_standby_feedback' do
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

      it 'disables the log_checkpoints setting' do
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

      it 'disables track_io_timing' do
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

      it 'enables the synchronous_commit setting' do
        expect(chef_run.node['postgresql']['synchronous_commit'])
          .to eq('on')

        expect(chef_run).to render_file(
          runtime_conf
        ).with_content(/synchronous_commit = on/)
      end
    end

    context 'when rendering pg_hba.conf' do
      it 'creates a standard pg_hba.conf' do
        expect(chef_run).to render_file(pg_hba_conf)
          .with_content('local   all         all                               peer map=gitlab')
      end

      it 'cert authentication is disabled by default' do
        expect(chef_run).to render_file(pg_hba_conf).with_content { |content|
          expect(content).to_not match(/cert$/)
        }
      end
    end
  end

  context 'with user specified settings' do
    before do
      stub_gitlab_rb(postgresql: {
                       shared_preload_libraries: 'pg_stat_statements',
                       archive_mode: 'on',
                       username: 'foo',
                       group: 'bar',
                       ssl: 'off',
                       ssl_crl_file: 'revoke.crl',
                       ssl_ciphers: 'ALL',
                       log_destination: 'csvlog',
                       logging_collector: 'on',
                       log_filename: 'test.log',
                       log_file_mode: '0600',
                       log_truncate_on_rotation: 'on',
                       log_rotation_age: '1d',
                       log_rotation_size: '10MB',
                       dynamic_shared_memory_type: 'none',
                       wal_log_hints: 'on'
                     },
                     geo_secondary_role: {
                       enable: true
                     })
    end

    it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'foo', 'bar'

    context 'when rendering postgresql.conf' do
      it 'correctly sets the shared_preload_libraries setting' do
        expect(chef_run.node['postgresql']['shared_preload_libraries'])
          .to eql('pg_stat_statements')

        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
      end

      it 'enables archive mode' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/archive_mode = on/)
      end

      it 'disables SSL' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl = off/)

        expect(chef_run).not_to render_file(postgresql_ssl_cert)
        expect(chef_run).not_to render_file(postgresql_ssl_key)
      end

      it 'sets the certificate revocation list' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_crl_file = 'revoke.crl'/)
      end

      it 'sets the SSL cipher list' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/ssl_ciphers = 'ALL'/)
      end

      it 'includes gitlab-geo.conf in postgresql.conf' do
        expect(chef_run).to render_file(postgresql_conf)
          .with_content(/include_if_exists 'gitlab-geo.conf'/)
      end

      it 'sets user specified logging parameters' do
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

      it 'sets the dynamic_shared_memory_type' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/^dynamic_shared_memory_type = none/)
      end

      it 'enables wal_log_hints' do
        expect(chef_run).to render_file(
          postgresql_conf
        ).with_content(/^wal_log_hints = on/)
      end
    end

    context 'when rendering runtime.conf' do
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

      it 'correctly sets the log_statement setting' do
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

    context 'when rendering pg_hba.conf' do
      before do
        stub_gitlab_rb(
          postgresql: {
            hostssl: true,
            trust_auth_cidr_addresses: ['127.0.0.1/32'],
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
            },
            cert_auth_addresses: {
              '1.2.3.4/32' => {
                database: 'fakedatabase',
                user: 'fakeuser'
              },
              'fakehostname' => {
                database: 'anotherfakedatabase',
                user: 'anotherfakeuser'
              },
            }
          }
        )
      end

      it 'prefers hostssl when configured in pg_hba.conf' do
        expect(chef_run).to render_file(pg_hba_conf)
          .with_content('hostssl    all         all         127.0.0.1/32           trust')
      end

      it 'adds users custom entries to pg_hba.conf' do
        expect(chef_run).to render_file(pg_hba_conf)
          .with_content('host foo bar 127.0.0.1/32 trust')
      end

      it 'allows cert authentication to be enabled' do
        expect(chef_run).to render_file(pg_hba_conf).with_content('hostssl fakedatabase fakeuser 1.2.3.4/32 cert')
        expect(chef_run).to render_file(pg_hba_conf).with_content('hostssl anotherfakedatabase anotherfakeuser fakehostname cert')
      end
    end
  end

  context 'when postgresql.conf changes' do
    before do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('postgresql').and_return(true)
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).with('postgresql').and_return(true)
    end

    it 'notifies reload postgresql task' do
      expect(chef_run).to create_postgresql_config('gitlab')
      postgresql_config = chef_run.postgresql_config('gitlab')
      expect(postgresql_config).to notify('execute[reload postgresql]').to(:run).immediately
      expect(postgresql_config).to notify('execute[start postgresql]').to(:run).immediately
    end
  end

  context 'when enabling extensions' do
    it 'creates the pg_trgm extension when it is possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('pg_trgm', 'gitlabhq_production').and_return(true)
      expect(chef_run).to enable_postgresql_extension('pg_trgm')
    end

    it 'does not create the pg_trgm extension if it is not possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('pg_trgm', 'gitlabhq_production').and_return(false)
      expect(chef_run).not_to run_execute('enable pg_trgm extension')
    end

    context 'when on a secondary database node' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(true)
        allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
      end

      it 'should not activate pg_trgm' do
        expect(chef_run).not_to run_execute('enable pg_trgm extension')
      end
    end

    it 'creates the btree_gist extension when it is possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('btree_gist', 'gitlabhq_production').and_return(true)
      expect(chef_run).to enable_postgresql_extension('btree_gist')
    end

    it 'does not create the btree_gist extension if it is not possible' do
      allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('btree_gist', 'gitlabhq_production').and_return(false)
      expect(chef_run).not_to run_execute('enable btree_gist extension')
    end
  end

  context 'when configuring postgresql_user resources' do
    before do
      stub_gitlab_rb(
        {
          postgresql: {
            sql_user_password: 'fakepassword',
            sql_replication_password: 'fakepassword'
          }
        }
      )
    end

    context 'when on the primary database node' do
      before do
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
    end

    context 'when on a secondary database node' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(true)
        allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
      end

      it 'should not create users' do
        expect(chef_run).not_to create_postgresql_user('gitlab')
        expect(chef_run).not_to create_postgresql_user('gitlab_replicator')
      end
    end
  end
end

RSpec.describe 'postgresql 13' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }
  let(:postgresql_conf) { File.join(postgresql_data_dir, 'postgresql.conf') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }

  before do
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('13.0'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('13.0'))
  end

  it 'configures wal_keep_size instead of wal_keep_segments' do
    expect(chef_run).to render_file(runtime_conf).with_content { |content|
      expect(content).to include("wal_keep_size")
      expect(content).not_to include("wal_keep_segments")
    }
  end
end

RSpec.describe 'postgresql 12' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }
  let(:postgresql_conf) { File.join(postgresql_data_dir, 'postgresql.conf') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }

  before do
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('12.0'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('12.0'))
  end

  it 'configures wal_keep_segments instead of wal_keep_size' do
    expect(chef_run).to render_file(runtime_conf).with_content { |content|
      expect(content).to include("wal_keep_segments")
      expect(content).to_not include("wal_keep_size")
    }
  end
end

RSpec.describe 'postgres when version mismatches occur' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }
  let(:postgresql_conf) { File.join(postgresql_data_dir, 'postgresql.conf') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }

  context 'when data and binary versions differ' do
    before do
      allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('reality'))
      allow(File).to receive(:exists?).and_call_original
      allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/reality*").and_return(
        ['/opt/gitlab/embedded/postgresql/reality']
      )
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/reality/bin/*").and_return(
        %w(
          /opt/gitlab/embedded/postgresql/reality/bin/foo_one
          /opt/gitlab/embedded/postgresql/reality/bin/foo_two
          /opt/gitlab/embedded/postgresql/reality/bin/foo_three
        )
      )
    end

    it 'corrects symlinks to the correct location' do
      allow(FileUtils).to receive(:ln_sf).and_return(true)
      %w(foo_one foo_two foo_three).each do |pg_bin|
        expect(FileUtils).to receive(:ln_sf).with(
          "/opt/gitlab/embedded/postgresql/reality/bin/#{pg_bin}",
          "/opt/gitlab/embedded/bin/#{pg_bin}"
        )
      end
      chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
    end

    it 'does not warn the user that a restart is needed by default' do
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
    end
  end

  context 'when running version and installed version differ' do
    before do
      allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('expectation'))
      allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('reality'))
    end

    it 'warns the user that a restart is needed' do
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      expect(chef_run).to run_ruby_block('warn pending postgresql restart')
    end

    it 'does not warns the user that a restart is needed when postgres is stopped' do
      expect(chef_run).not_to run_ruby_block('warn pending postgresql restart')
    end
  end

  context 'when an older data version is present and no longer used' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('new_shiny'))
      allow_any_instance_of(PGVersion).to receive(:major).and_return('new_shiny')
      allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('new_shiny'))
      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('ancient_history'))
      allow(File).to receive(:exists?).and_call_original
      allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/ancient_history*").and_return([])
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/new_shiny*").and_return(
        ['/opt/gitlab/embedded/postgresql/new_shiny']
      )
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/new_shiny/bin/*").and_return(
        %w(
          /opt/gitlab/embedded/postgresql/new_shiny/bin/foo_one
          /opt/gitlab/embedded/postgresql/new_shiny/bin/foo_two
          /opt/gitlab/embedded/postgresql/new_shiny/bin/foo_three
        )
      )
    end

    it 'corrects symlinks to the correct location' do
      allow(FileUtils).to receive(:ln_sf).and_return(true)
      %w(foo_one foo_two foo_three).each do |pg_bin|
        expect(FileUtils).to receive(:ln_sf).with(
          "/opt/gitlab/embedded/postgresql/new_shiny/bin/#{pg_bin}",
          "/opt/gitlab/embedded/bin/#{pg_bin}"
        )
      end
      chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
    end
  end

  context 'when the expected postgres version is missing' do
    before do
      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('how_it_started'))
      allow(File).to receive(:exists?).and_call_original
      allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/how_it_started*").and_return([])
      allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/how_it_is_going*").and_return([])
    end

    it 'throws an error' do
      expect do
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end.to raise_error(RuntimeError, /Could not find PostgreSQL binaries/)
    end
  end
end

RSpec.describe 'postgresql::bin' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:gitlab_psql_rc) do
    <<-EOF
psql_user='gitlab-psql'
psql_group='gitlab-psql'
psql_host='/var/opt/gitlab/postgresql'
psql_port='5432'
    EOF
  end

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

    it 'includes postgresql::directory_locations' do
      expect(chef_run).to include_recipe('postgresql::directory_locations')
    end

    it 'creates gitlab-psql-rc' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-psql-rc')
        .with_content(gitlab_psql_rc)
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

RSpec.describe 'default directories' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'postgresql directory' do
    context 'with default settings' do
      it 'creates postgresql directory' do
        expect(chef_run).to create_directory('/var/opt/gitlab/postgresql').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
      end
    end

    context 'with custom settings' do
      before do
        stub_gitlab_rb(
          postgresql: {
            dir: '/mypgdir',
            home: '/mypghomedir'
          })
      end

      it 'creates postgresql directory with custom path' do
        expect(chef_run).to create_directory('/mypgdir').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
      end
    end
  end
end
