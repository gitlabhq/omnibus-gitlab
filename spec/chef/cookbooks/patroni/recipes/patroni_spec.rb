require 'chef_helper'
require 'yaml'

RSpec.describe 'patroni cookbook' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: %w(database_objects)).converge('gitlab-ee::default')
  end

  it 'should be disabled by default' do
    expect(chef_run).to include_recipe('patroni::disable')
  end

  context 'when postgres_role is enabled' do
    before do
      stub_gitlab_rb(roles: %w(postgres_role))
    end

    it 'should be disabled' do
      expect(chef_run).to include_recipe('patroni::disable')
    end
  end

  context 'when patroni_role is configured' do
    before do
      stub_gitlab_rb(roles: %w(patroni_role))
    end

    it 'should be enabled' do
      expect(chef_run).to include_recipe('patroni::enable')
    end
  end

  context 'when patroni_role and postgres_role are configured' do
    before do
      stub_gitlab_rb(roles: %w(postgres_role patroni_role))
    end

    it 'should be enabled' do
      expect(chef_run).to include_recipe('patroni::enable')
    end
  end

  context 'when enabled with default config' do
    before do
      stub_gitlab_rb(
        roles: %w(patroni_role),
        postgresql: {
          pgbouncer_user_password: ''
        }
      )
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:bootstrapped?).and_return(false)
      allow_any_instance_of(PgHelper).to receive(:is_replica?).and_return(false)
    end

    let(:default_patroni_config_pg13) do
      {
        name: 'fauxhai.local',
        scope: 'postgresql-ha',
        log: {
          level: 'INFO'
        },
        consul: {
          url: 'http://127.0.0.1:8500',
          service_check_interval: '10s',
          register_service: true,
          checks: [],
        },
        postgresql: {
          bin_dir: '/opt/gitlab/embedded/bin',
          data_dir: '/var/opt/gitlab/postgresql/data',
          config_dir: '/var/opt/gitlab/postgresql/data',
          listen: :'5432',
          connect_address: "#{Patroni.private_ipv4}:5432",
          use_unix_socket: true,
          parameters: {
            unix_socket_directories: '/var/opt/gitlab/postgresql'
          },
          authentication: {
            superuser: {
              username: 'gitlab-psql'
            },
            replication: {
              username: 'gitlab_replicator'
            },
          },
          remove_data_directory_on_diverged_timelines: false,
          remove_data_directory_on_rewind_failure: false,
          basebackup: [
            'no-password'
          ],
        },
        bootstrap: {
          dcs: {
            loop_wait: 10,
            ttl: 30,
            retry_timeout: 10,
            maximum_lag_on_failover: 1_048_576,
            max_timelines_history: 0,
            master_start_timeout: 300,
            postgresql: {
              use_pg_rewind: true,
              use_slots: true,
              parameters: {
                wal_level: 'replica',
                hot_standby: 'on',
                wal_keep_size: 160,
                max_replication_slots: 5,
                max_connections: 200,
                max_locks_per_transaction: 128,
                max_worker_processes: 8,
                max_wal_senders: 5,
                checkpoint_timeout: 30,
                max_prepared_transactions: 0,
                track_commit_timestamp: 'off',
                wal_log_hints: 'off'
              },
            },
            slots: {},
          },
          method: 'gitlab_ctl',
          gitlab_ctl: {
            command: '/opt/gitlab/bin/gitlab-ctl patroni bootstrap --srcdir=/var/opt/gitlab/patroni/data'
          }
        },
        restapi: {
          listen: :'8008',
          connect_address: "#{Patroni.private_ipv4}:8008",
          allowlist_include_members: false
        },
      }
    end

    let(:default_patroni_config) do
      {
        name: 'fauxhai.local',
        scope: 'postgresql-ha',
        log: {
          level: 'INFO'
        },
        consul: {
          url: 'http://127.0.0.1:8500',
          service_check_interval: '10s',
          register_service: true,
          checks: [],
        },
        postgresql: {
          bin_dir: '/opt/gitlab/embedded/bin',
          data_dir: '/var/opt/gitlab/postgresql/data',
          config_dir: '/var/opt/gitlab/postgresql/data',
          listen: :'5432',
          connect_address: "#{Patroni.private_ipv4}:5432",
          use_unix_socket: true,
          parameters: {
            unix_socket_directories: '/var/opt/gitlab/postgresql'
          },
          authentication: {
            superuser: {
              username: 'gitlab-psql'
            },
            replication: {
              username: 'gitlab_replicator'
            },
          },
          remove_data_directory_on_diverged_timelines: false,
          remove_data_directory_on_rewind_failure: false,
          basebackup: [
            'no-password'
          ],
        },
        bootstrap: {
          dcs: {
            loop_wait: 10,
            ttl: 30,
            retry_timeout: 10,
            maximum_lag_on_failover: 1_048_576,
            max_timelines_history: 0,
            master_start_timeout: 300,
            postgresql: {
              use_pg_rewind: true,
              use_slots: true,
              parameters: {
                wal_level: 'replica',
                hot_standby: 'on',
                wal_keep_segments: 10,
                max_replication_slots: 5,
                max_connections: 200,
                max_locks_per_transaction: 128,
                max_worker_processes: 8,
                max_wal_senders: 5,
                checkpoint_timeout: 30,
                max_prepared_transactions: 0,
                track_commit_timestamp: 'off',
                wal_log_hints: 'off'
              },
            },
            slots: {},
          },
          method: 'gitlab_ctl',
          gitlab_ctl: {
            command: '/opt/gitlab/bin/gitlab-ctl patroni bootstrap --srcdir=/var/opt/gitlab/patroni/data'
          }
        },
        restapi: {
          listen: :'8008',
          connect_address: "#{Patroni.private_ipv4}:8008",
          allowlist_include_members: false
        },
      }
    end

    it 'should enable patroni service and disable postgresql runit service' do
      expect(chef_run).to enable_runit_service('patroni')
      expect(chef_run).to disable_runit_service('postgresql')
    end

    it 'should notify patroni service to hup' do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('patroni').and_return(true)

      expect(chef_run.template('/var/opt/gitlab/patroni/patroni.yaml')).to notify('runit_service[patroni]').to(:hup)
    end

    it 'should skip standalone postgresql configuration' do
      expect(chef_run).to create_postgresql_config('gitlab')
      expect(chef_run.postgresql_config('gitlab')).not_to notify('execute[start postgresql]').to(:run)
      expect(chef_run).not_to run_execute(/(start|reload) postgresql/)
    end

    it 'should create database objects (roles, databses, extension)' do
      expect(chef_run).not_to run_execute('/opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8')
      expect(chef_run).to create_postgresql_user('gitlab')
      expect(chef_run).to create_postgresql_user('gitlab_replicator')
      expect(chef_run).to create_pgbouncer_user('rails')
      expect(chef_run).to create_postgresql_database('gitlabhq_production')
      expect(chef_run).to enable_postgresql_extension('pg_trgm')
      expect(chef_run).to enable_postgresql_extension('btree_gist')
    end

    it 'should create patroni configuration file for PostgreSQL 12' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        expect(YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)).to eq(default_patroni_config)
      }
    end

    it 'should create patroni configuration file for PostgreSQL 13' do
      allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('13.0'))
      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('13.0'))

      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        expect(YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)).to eq(default_patroni_config_pg13)
      }
    end
  end

  context 'when enabled with specific config' do
    before do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        postgresql: {
          username: 'test_psql_user',
          sql_user: 'test_sql_user',
          sql_user_password: 'dbda601b8d4dc3d1697ef84dbbb8e61b',
          sql_replication_user: 'test_sql_replication_user',
          sql_replication_password: '48e84afb4b268128ac14f7c66fc7af42',
          pgbouncer_user: 'test_pgbouncer_user',
          pgbouncer_user_password: '2bc94731612abb74aea7805a41dfcb09',
          connect_port: 15432,
        },
        patroni: {
          enable: true,
          scope: 'test-scope',
          name: 'test-node-name',
          log_level: 'DEBUG',
          loop_wait: 20,
          ttl: 60,
          master_start_timeout: 600,
          use_slots: false,
          use_pg_rewind: true,
          connect_address: '1.2.3.4',
          connect_port: 18008,
          username: 'gitlab',
          password: 'restapipassword',
          replication_password: 'fakepassword',
          allowlist: ['1.2.3.4/32', '127.0.0.1/32'],
          allowlist_include_members: false,
          remove_data_directory_on_diverged_timelines: true,
          remove_data_directory_on_rewind_failure: true,
          replication_slots: {
            'geo_secondary' => { 'type' => 'physical' }
          },
          consul: {
            service_check_interval: '20s'
          },
          postgresql: {
            wal_keep_segments: 16,
            max_wal_senders: 4,
            max_replication_slots: 4
          },
          tags: {
            nofailover: true
          },
          callbacks: {
            on_role_change: "/patroni/scripts/post-failover-maintenance.sh"
          },
          recovery_conf: {
            restore_command: "/opt/wal-g/bin/wal-g wal-fetch %f %p"
          }
        }
      )
    end

    it 'should be reflected in patroni configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg).to include(
          name: 'test-node-name',
          scope: 'test-scope',
          log: {
            level: 'DEBUG'
          },
          tags: {
            nofailover: true
          }
        )
        expect(cfg[:consul][:service_check_interval]).to eq('20s')
        expect(cfg[:postgresql][:connect_address]).to eq('1.2.3.4:15432')
        expect(cfg[:postgresql][:authentication]).to eq(
          superuser: {
            username: 'test_psql_user'
          },
          replication: {
            username: 'test_sql_replication_user',
            password: 'fakepassword'
          }
        )
        expect(cfg[:postgresql][:callbacks]).to eq(
          on_role_change: "/patroni/scripts/post-failover-maintenance.sh"
        )
        expect(cfg[:postgresql][:recovery_conf]).to eq(
          restore_command: "/opt/wal-g/bin/wal-g wal-fetch %f %p"
        )
        expect(cfg[:restapi]).to include(
          connect_address: '1.2.3.4:18008',
          authentication: {
            username: 'gitlab',
            password: 'restapipassword'
          },
          allowlist: ['1.2.3.4/32', '127.0.0.1/32'],
          allowlist_include_members: false
        )
        expect(cfg[:bootstrap][:dcs]).to include(
          loop_wait: 20,
          ttl: 60,
          master_start_timeout: 600,
          slots: {
            geo_secondary: { type: 'physical' }
          }
        )
        expect(cfg[:bootstrap][:dcs][:postgresql]).to include(
          use_slots: false,
          use_pg_rewind: true
        )
        expect(cfg[:bootstrap][:dcs][:postgresql][:parameters]).to include(
          wal_keep_segments: 16,
          max_wal_senders: 4,
          max_replication_slots: 4
        )
        expect(cfg[:postgresql][:remove_data_directory_on_rewind_failure]).to be true
        expect(cfg[:postgresql][:remove_data_directory_on_diverged_timelines]).to be true
      }
    end

    it 'should reflect into dcs config file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg).to include(
          loop_wait: 20,
          ttl: 60,
          master_start_timeout: 600,
          slots: {
            geo_secondary: { type: 'physical' }
          }
        )
        expect(cfg[:postgresql]).to include(
          use_slots: false,
          use_pg_rewind: true
        )
        expect(cfg[:postgresql][:parameters]).to include(
          wal_keep_segments: 16,
          max_wal_senders: 4,
          max_replication_slots: 4
        )
      }
    end
  end

  context 'when standby cluster is enabled' do
    before do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        patroni: {
          enable: true,
          use_pg_rewind: true,
          replication_password: 'fakepassword',
          standby_cluster: {
            enable: true,
            host: '1.2.3.4',
            port: 5432,
            primary_slot_name: 'geo_secondary'
          }
        },
        postgresql: {
          sql_user_password: 'a4125c87ce2572ce271cd77e0de9a0ad',
          sql_replication_password: 'e64b415e9b9a34ac7ac6e53ae16ccacb',
          md5_auth_cidr_addresses: '1.2.3.4/32'
        }
      )
    end

    it 'should be reflected in patroni configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg[:postgresql][:authentication]).to include(
          replication: {
            username: 'gitlab_replicator',
            password: 'fakepassword'
          }
        )
        expect(cfg[:bootstrap][:dcs]).to include(
          standby_cluster: {
            host: '1.2.3.4',
            port: 5432,
            primary_slot_name: 'geo_secondary'
          }
        )
        expect(cfg[:bootstrap][:dcs][:postgresql]).to include(
          use_pg_rewind: true
        )
      }
    end

    it 'should reflect into dcs config file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg).to include(
          standby_cluster: {
            host: '1.2.3.4',
            port: 5432,
            primary_slot_name: 'geo_secondary'
          }
        )
        expect(cfg[:postgresql]).to include(
          use_pg_rewind: true
        )
      }
    end
  end

  context 'when building a cluster' do
    before do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        patroni: {
          enable: true
        }
      )
    end

    context 'from scratch' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(false)
      end

      it 'should enable patroni service and disable postgresql runit service' do
        expect(chef_run).to enable_runit_service('patroni')
        expect(chef_run).to disable_runit_service('postgresql')
      end
    end

    context 'converting a standalone instance to a cluster member' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
        allow_any_instance_of(PatroniHelper).to receive(:node_status).and_return('running')
      end

      it 'should signal to node to restart postgresql and disable its runit service' do
        expect(chef_run).to enable_runit_service('patroni')
        expect(chef_run).to disable_runit_service('postgresql')
        expect(chef_run).to run_execute('signal to restart postgresql')
      end
    end

    context 'on a replica' do
      before do
        allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
      end

      it 'should not create database objects' do
        expect(chef_run).not_to create_postgresql_user('gitlab')
        expect(chef_run).not_to create_postgresql_user('gitlab_replicator')
        expect(chef_run).not_to create_pgbouncer_user('patroni')
        expect(chef_run).not_to run_execute('create gitlabhq_production database')
        expect(chef_run).not_to enable_postgresql_extension('pg_trgm')
        expect(chef_run).not_to enable_postgresql_extension('btree_gist')
      end
    end
  end

  context 'postgresql dynamic configuration' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    context 'with no explicit override' do
      before do
        stub_gitlab_rb(
          roles: %w(postgres_role),
          patroni: {
            enable: true
          }
        )
      end

      it 'should use default values from postgresql cookbook and handle corner cases' do
        expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
          cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

          expect(cfg[:postgresql][:use_pg_rewind]).to be(true)
          expect(cfg[:postgresql][:parameters]).to include(
            max_connections: 200,
            max_locks_per_transaction: 128,
            max_worker_processes: 8,
            max_prepared_transactions: 0,
            track_commit_timestamp: 'off',
            wal_log_hints: 'off',
            max_wal_senders: 5,
            max_replication_slots: 5,
            wal_keep_segments: 10,
            checkpoint_timeout: 30
          )
        }
      end
    end

    context 'with no explicit override and non-default postgresql settings' do
      before do
        stub_gitlab_rb(
          roles: %w(postgres_role),
          patroni: {
            enable: true,
          },
          postgresql: {
            max_connections: 123,
            max_locks_per_transaction: 321,
            max_worker_processes: 12,
            wal_log_hints: 'foo',
            max_wal_senders: 11,
            max_replication_slots: 13,
          }
        )
      end

      it 'should use default values from postgresql cookbook' do
        expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
          cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

          expect(cfg[:postgresql][:use_pg_rewind]).to be(true)
          expect(cfg[:postgresql][:parameters]).to include(
            max_connections: 123,
            max_locks_per_transaction: 321,
            max_worker_processes: 12,
            max_prepared_transactions: 0,
            track_commit_timestamp: 'off',
            wal_log_hints: 'foo',
            max_wal_senders: 11,
            max_replication_slots: 13,
            wal_keep_segments: 10,
            checkpoint_timeout: 30
          )
        }
      end
    end

    context 'with explicit override' do
      before do
        stub_gitlab_rb(
          roles: %w(postgres_role),
          patroni: {
            enable: true,
            postgresql: {
              max_connections: 100,
              max_locks_per_transaction: 64,
              max_worker_processes: 4,
              wal_log_hints: 'on',
              max_wal_senders: 0,
              max_replication_slots: 0,
              checkpoint_timeout: '5min'
            }
          }
        )
      end

      it 'should use default values from postgresql cookbook' do
        expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
          cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

          expect(cfg[:postgresql][:use_pg_rewind]).to be(true)
          expect(cfg[:postgresql][:parameters]).to include(
            max_connections: 100,
            max_locks_per_transaction: 64,
            max_worker_processes: 4,
            max_wal_senders: 0,
            max_replication_slots: 0,
            wal_log_hints: 'on'
          )
        }
      end
    end

    context 'when pg_rewind is enabled' do
      before do
        stub_gitlab_rb(
          roles: %w(postgres_role),
          patroni: {
            enable: true,
            use_pg_rewind: true,
            remove_data_directory_on_diverged_timelines: true,
            remove_data_directory_on_rewind_failure: true
          }
        )
      end

      it 'should use default values from postgresql cookbook' do
        expect(chef_run).to render_file('/var/opt/gitlab/patroni/dcs.yaml').with_content { |content|
          cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

          expect(cfg[:postgresql][:use_pg_rewind]).to be(true)
          expect(cfg[:postgresql][:parameters]).to include(
            max_connections: 200,
            max_locks_per_transaction: 128,
            max_worker_processes: 8,
            wal_log_hints: 'on'
          )
        }
      end
    end
  end

  context 'when patroni is enabled but consul is not' do
    let(:chef_run) do
      converge_config('gitlab-ee::default', is_ee: true)
    end

    before do
      stub_gitlab_rb(
        patroni: {
          enable: true
        }
      )
    end

    it 'expects a warning to be printed' do
      chef_run

      expect_logged_warning(/Patroni is enabled but Consul seems to be disabled/)
    end
  end

  context 'when tls is enabled' do
    it 'should only set the path to the tls certificate and key' do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        patroni: {
          enable: true,
          tls_certificate_file: '/path/to/crt.pem',
          tls_key_file: '/path/to/key.pem'
        }
      )

      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg[:restapi][:certfile]).to eq('/path/to/crt.pem')
        expect(cfg[:restapi][:keyfile]).to eq('/path/to/key.pem')
        expect(cfg[:restapi][:keyfile_password]).to be(nil)
        expect(cfg[:restapi][:cafile]).to be(nil)
        expect(cfg[:restapi][:ciphers]).to be(nil)
        expect(cfg[:restapi][:verify_client]).to be(nil)
        expect(cfg[:ctl]).to be(nil)
      }
    end

    it 'should set all available tls configuration including tls certificate and key paths' do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        patroni: {
          enable: true,
          tls_certificate_file: '/path/to/crt.pem',
          tls_key_file: '/path/to/key.pem',
          tls_key_password: 'fakepassword',
          tls_ca_file: '/path/to/ca.pem',
          tls_ciphers: 'CIPHERS LIST',
          tls_client_mode: 'optional',
          tls_client_certificate_file: '/path/to/client.pem',
          tls_client_key_file: '/path/to/client.key'
        }
      )

      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        cfg = YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)

        expect(cfg[:restapi][:certfile]).to eq('/path/to/crt.pem')
        expect(cfg[:restapi][:keyfile]).to eq('/path/to/key.pem')
        expect(cfg[:restapi][:keyfile_password]).to eq('fakepassword')
        expect(cfg[:restapi][:cafile]).to eq('/path/to/ca.pem')
        expect(cfg[:restapi][:ciphers]).to eq('CIPHERS LIST')
        expect(cfg[:restapi][:verify_client]).to eq('optional')
        expect(cfg[:ctl][:insecure]).to eq(false)
        expect(cfg[:ctl][:certfile]).to eq('/path/to/client.pem')
        expect(cfg[:ctl][:keyfile]).to eq('/path/to/client.key')
      }
    end
  end
end
