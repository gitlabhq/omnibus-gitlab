require 'chef_helper'
require 'yaml'

describe 'patroni cookbook' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new.converge('gitlab-ee::default')
  end

  it 'should be disabled by default' do
    expect(chef_run).to include_recipe('patroni::disable')
  end

  context 'when repmgr is enabled' do
    before do
      stub_gitlab_rb(
        roles: %w(postgres_role)
      )
    end

    it 'should be disabled while repmgr is enabled' do
      expect(chef_run).to include_recipe('repmgr::enable')
      expect(chef_run).to include_recipe('patroni::disable')
    end
  end

  context 'when enabled with default config' do
    before do
      stub_gitlab_rb(
        roles: %w(postgres_role),
        patroni: {
          enable: true
        }
      )
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:bootstrapped?).and_return(false)
    end

    let(:default_patroni_config) do
      {
        name: 'fauxhai.local',
        scope: 'gitlab-postgresql-ha',
        log: {
          level: 'INFO'
        },
        consul: {
          url: 'http://127.0.0.1:8500',
          service_check_interval: '10s',
          register_service: false,
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
              use_pg_rewind: false,
              use_slots: true,
              parameters: {
                wal_level: 'replica',
                hot_standby: 'on',
                wal_keep_segments: 8,
                max_replication_slots: 5,
                max_wal_senders: 5,
                checkpoint_timeout: 30,
              },
            },
          },
          method: 'gitlab_ctl',
          gitlab_ctl: {
            command: '/opt/gitlab/bin/gitlab-ctl patroni bootstrap'
          }
        },
        restapi: {
          listen: :'8008',
          connect_address: "#{Patroni.private_ipv4}:8008",
        },
      }
    end

    it 'should be enabled while repmgr is disabled' do
      expect(chef_run).to include_recipe('repmgr::disable')
      expect(chef_run).to include_recipe('patroni::enable')
      expect(chef_run).to include_recipe('postgresql::enable')
      expect(chef_run).to include_recipe('consul::enable')
    end

    it 'should enable patroni service and disable postgresql runit service' do
      expect(chef_run).to enable_runit_service('patroni')
      expect(chef_run).to disable_runit_service('postgresql')
    end

    it 'should skip standalone postgresql configuration' do
      expect(chef_run).to create_postgresql_config('gitlab')
      expect(chef_run.postgresql_config('gitlab')).not_to notify('execute[start postgresql]').to(:run)
      expect(chef_run).not_to run_execute(/(start|reload) postgresql/)
    end

    it 'should create database objects (roles, databses, extension)', focus: true do
      expect(chef_run).not_to run_execute('/opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8')
      expect(chef_run).to create_postgresql_user('gitlab')
      expect(chef_run).to create_postgresql_user('gitlab_replicator')
      expect(chef_run).to create_pgbouncer_user('patroni')
      expect(chef_run).to run_execute('create gitlabhq_production database')
      expect(chef_run).to enable_postgresql_extension('pg_trgm')
      expect(chef_run).to enable_postgresql_extension('btree_gist')
    end

    it 'should create patroni configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        expect(YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)).to eq(default_patroni_config)
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
          sql_user_password: '32596e8376077c3ef8d5cf52f15279ba',
          sql_replication_user: 'test_sql_replication_user',
          sql_replication_password: '5b3e5a380c8fe8f8180d396be021951a',
          pgbouncer_user: 'test_pgbouncer_user',
          pgbouncer_user_password: '3b244bd6e459bc406013417367587d41',
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
          consul: {
            service_check_interval: '20s'
          },
          postgresql: {
            wal_keep_segments: 16,
            max_wal_senders: 4,
            max_replication_slots: 4
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
            password: 'md55b3e5a380c8fe8f8180d396be021951a'
          }
        )
        expect(cfg[:restapi][:connect_address]).to eq('1.2.3.4:18008')
        expect(cfg[:bootstrap][:dcs]).to include(
          loop_wait: 20,
          ttl: 60,
          master_start_timeout: 600
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

      it 'should enable patroni service and skip disabling postgresql runit service' do
        expect(chef_run).to enable_runit_service('patroni')
        expect(chef_run).not_to disable_runit_service('postgresql')
      end
    end

    context 'switching from repmgr' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
        allow_any_instance_of(PatroniHelper).to receive(:node_status).and_return('running')
        allow_any_instance_of(PatroniHelper).to receive(:repmgr_data_present?).and_return(true)
      end

      it 'should not signal to node to restart postgresql but must disable its runit service' do
        expect(chef_run).to enable_runit_service('patroni')
        expect(chef_run).to disable_runit_service('postgresql')
        expect(chef_run).not_to run_execute('signal to restart postgresql')
      end
    end

    context 'converting a standalone instance to a cluster member' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
        allow_any_instance_of(PatroniHelper).to receive(:node_status).and_return('running')
        allow_any_instance_of(PatroniHelper).to receive(:repmgr_data_present?).and_return(false)
      end

      it 'should signal to node to restart postgresql and disable its runit service' do
        expect(chef_run).to enable_runit_service('patroni')
        expect(chef_run).to disable_runit_service('postgresql')
        expect(chef_run).to run_execute('signal to restart postgresql')
      end
    end
  end
end
