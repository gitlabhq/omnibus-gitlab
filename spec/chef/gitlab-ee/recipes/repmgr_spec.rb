require 'chef_helper'

describe 'repmgr' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab-ee::default') }

  let(:repmgr_conf) { '/var/opt/gitlab/postgresql/repmgr.conf' }

  let(:hba_block) do
    <<-EOF
    EOF
  end

  let(:repmgr_conf_block) do
    <<-EOF
cluster=gitlab_cluster
node=1647392869
node_name=fauxhai.local
conninfo='host=fauxhai.local port=5432 user=gitlab_repmgr dbname=gitlab_repmgr sslmode=prefer sslcompression=0'

use_replication_slots=0
loglevel=INFO
logfacility=STDERR
event_notification_command='gitlab-ctl repmgr-event-handler  %n %e %s "%t" "%d"'

pg_bindir=/opt/gitlab/embedded/bin

service_start_command = /opt/gitlab/bin/gitlab-ctl start postgresql
service_stop_command = /opt/gitlab/bin/gitlab-ctl stop postgresql
service_restart_command = /opt/gitlab/bin/gitlab-ctl restart postgresql
service_reload_command = /opt/gitlab/bin/gitlab-ctl hup postgresql
failover = automatic
promote_command = /opt/gitlab/embedded/bin/repmgr standby promote -f /var/opt/gitlab/postgresql/repmgr.conf
follow_command = /opt/gitlab/embedded/bin/repmgr standby follow -f /var/opt/gitlab/postgresql/repmgr.conf
monitor_interval_secs=2
master_response_timeout=60
reconnect_attempts=6
reconnect_interval=10
retry_promote_interval_secs=300
witness_repl_nodes_sync_interval_secs=15
    EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'repmgrd_disable' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('repmgr::repmgrd_disable') }
    it_behaves_like 'disabled runit service', 'repmgrd'
  end

  context 'repmgrd' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('repmgr::repmgrd') }
    it_behaves_like 'enabled runit service', 'repmgrd', 'root', 'root', 'gitlab-psql', 'gitlab-psql'
  end

  context 'disable' do
    it 'should include the repmgr::repmgrd_disable recipe' do
      expect(chef_run).to include_recipe('repmgr::repmgrd_disable')
    end
  end

  context 'disabled by default' do
    it 'should include the repmgr::disable recipe' do
      expect(chef_run).to include_recipe('repmgr::disable')
    end
  end

  context 'enabled with user specified config' do
    before do
      stub_gitlab_rb(
        repmgr: {
          enable: true,
          trust_auth_cidr_addresses: %w(123.456.789.0/24)
        },
        postgresql: {
          md5_auth_cidr_addresses: %w(0.0.0.0/0),
          trust_auth_cidr_addresses: %w(127.0.0.0/24),
          sql_user_password: 'fakemd5hash',
          hot_standby: 'on',
          wal_level: 'replica',
          max_wal_senders: 3,
          shared_preload_libraries: 'repmgr_funcs',
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'repmgrd', 'root', 'root', 'foo', 'bar'

    context 'by default' do
      it 'includes the repmgr::enable recipe' do
        expect(chef_run).to include_recipe('repmgr::enable')
      end

      it 'should include the repmgr::enable_daemon recipe' do
        expect(chef_run).to include_recipe('repmgr::repmgrd')
      end

      it 'sets up the repmgr specific entries in pg_hba.conf' do
        expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/pg_hba.conf')
          .with_content { |content|
            expect(content).to include('local replication gitlab_repmgr  trust')
            expect(content).to include('host replication gitlab_repmgr 127.0.0.1/32 trust')
            expect(content).to include('host replication gitlab_repmgr 123.456.789.0/24 trust')
            expect(content).to include('local gitlab_repmgr gitlab_repmgr  trust')
            expect(content).to include('host gitlab_repmgr gitlab_repmgr 127.0.0.1/32 trust')
            expect(content).to include('host gitlab_repmgr gitlab_repmgr 123.456.789.0/24 trust')
          }
      end

      it 'creates pg_hba.conf with custom entries and repmgr entries' do
        stub_gitlab_rb(
          postgresql: {
            custom_pg_hba_entries: {
              postgres: [
                {
                  type: 'host',
                  database: 'testing',
                  user: 'fakeuser',
                  cidr: '123.0.0.0/24',
                  method: 'md5'
                }
              ]
            }
          }
        )
        expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/pg_hba.conf')
          .with_content { |content|
            expect(content).to include('local replication gitlab_repmgr  trust')
            expect(content).to include('host replication gitlab_repmgr 127.0.0.1/32 trust')
            expect(content).to include('host replication gitlab_repmgr 123.456.789.0/24 trust')
            expect(content).to include('local gitlab_repmgr gitlab_repmgr  trust')
            expect(content).to include('host gitlab_repmgr gitlab_repmgr 127.0.0.1/32 trust')
            expect(content).to include('host gitlab_repmgr gitlab_repmgr 123.456.789.0/24 trust')
            expect(content).to include('# postgres')
            expect(content).to include('host testing fakeuser 123.0.0.0/24 md5')
          }
      end

      it 'creates repmgr.conf' do
        expect(chef_run).to render_file(repmgr_conf).with_content(repmgr_conf_block)
      end

      it 'creates the repmgr database' do
        expect(chef_run).to create_postgresql_database('gitlab_repmgr').with(owner: 'gitlab_repmgr')
      end

      it 'registers the master node' do
        resource = chef_run.postgresql_database('gitlab_repmgr')
        expect(resource).to notify('execute[register repmgr master node]').to(:run)
      end

      context 'with consul enabled' do
        it 'does not include the consul_user recipe without postgresql service' do
          stub_gitlab_rb(
            consul: {
              enable: true,
            }
          )
          expect(chef_run).not_to include_recipe('repmgr::consul_user')
        end

        it 'includes the consul_user_permissions recipe if the postgresql service is enabled' do
          stub_gitlab_rb(
            consul: {
              enable: true,
              services: %w(postgresql)
            }
          )

          expect(chef_run).to include_recipe('repmgr::consul_user_permissions')
        end
      end
    end

    context 'with non-default options' do
      it 'allows the user to specify node numbers' do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
            node_number: 12345
          }
        )
        expect(chef_run).to render_file(repmgr_conf).with_content('node=12345')
      end

      it 'allows the user to specify the node name' do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
            node_name: 'fakenodename'
          }
        )
        expect(chef_run).to render_file(repmgr_conf).with_content('node_name=fakenodename')
      end

      it 'allows the user to specify host name for the connection info' do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
            host: 'fakehostname'
          }
        )
        expect(chef_run).to render_file(repmgr_conf).with_content(
          %(conninfo='host=fakehostname port=5432 user=gitlab_repmgr dbname=gitlab_repmgr sslmode=prefer sslcompression=0')
        )
      end

      it 'allows the user to specify port number for the connection info' do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
            port: 7777
          }
        )
        expect(chef_run).to render_file(repmgr_conf).with_content(
          %(conninfo='host=fauxhai.local port=7777 user=gitlab_repmgr dbname=gitlab_repmgr sslmode=prefer sslcompression=0')
        )
      end

      it 'does not attempt to register node as master if user specified so' do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
            master_on_initialization: false
          }
        )
        resource = chef_run.postgresql_database('gitlab_repmgr')
        expect(resource).not_to notify('execute[register repmgr master node]').to(:run)
      end
    end

    context 'user disabled the daemon' do
      before do
        stub_gitlab_rb(
          repmgr: {
            enable: true,
          },
          repmgrd: {
            enable: false
          }
        )
      end

      it 'includes the repmgrd recipe' do
        expect(chef_run).not_to include_recipe('repmgr::repmgrd')
      end

      it_behaves_like 'disabled runit service', 'repmgrd'
    end
  end

  describe 'repmgr::consul_user_permissions' do
    before do
      stub_gitlab_rb(
        repmgr: {
          enable: true
        },
        consul: {
          enable: true,
          services: %w(postgresql)
        }
      )
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:user_exists?).with('gitlab-consul').and_return(false)
    end

    let(:postgresql_user) { chef_run.postgresql_user('gitlab-consul') }

    it 'creates the consul database user' do
      expect(chef_run).to create_postgresql_user 'gitlab-consul'
    end

    it 'grants the appropriate permissions on the gitlab_repmgr database to the gitlab-consul user' do
      expect(postgresql_user).to notify('execute[grant read only access to repmgr]').to(:run).delayed
    end
  end

  context 'user specifically disabled master node registration' do
    before do
      stub_gitlab_rb(
        repmgr: {
          enable: true,
          master_on_initialization: false
        },
        consul: {
          enable: true,
          services: %w(postgresql)
        }
      )
    end

    it 'does not include consul_user_permissions recipe on standby node' do
      expect(chef_run).not_to include_recipe('repmgr::consul_user_permissions')
    end
  end

  context 'with custom postgresql directory specified' do
    before do
      stub_gitlab_rb(
        repmgr: {
          enable: true
        },
        postgresql: {
          dir: "/foo/bar"
        }
      )
    end

    it 'creates conf file in correct location' do
      expect(chef_run).to render_file('/foo/bar/repmgr.conf')
    end

    it 'specifies correct location of conf file in service run file' do
      expect(chef_run).to render_file('/opt/gitlab/sv/repmgrd/run').with_content(/\/foo\/bar\/repmgr.conf/)
    end
  end
end
