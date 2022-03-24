#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chef_helper'

RSpec.describe 'pgbouncer' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:pgbouncer_ini) { '/var/opt/gitlab/pgbouncer/pgbouncer.ini' }
  let(:databases_json) { '/var/opt/gitlab/pgbouncer/databases.json' }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when enabled' do
    before do
      stub_gitlab_rb(
        pgbouncer: {
          enable: true,
          databases: {
            gitlabhq_production: {
              host: '1.2.3.4'
            }
          }
        },
        postgresql: {
          pgbouncer_user: 'fakeuser',
          pgbouncer_user_password: 'fakeuserpassword'
        }
      )
    end

    it 'includes the pgbouncer recipe' do
      expect(chef_run).to include_recipe('pgbouncer::enable')
    end

    it 'includes the postgresql user recipe' do
      expect(chef_run).to include_recipe('postgresql::user')
    end

    it_behaves_like 'enabled runit service', 'pgbouncer', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/pgbouncer/env').with_variables(default_vars)
    end

    it 'creates the appropriate directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/pgbouncer')
      expect(chef_run).to create_directory('/var/opt/gitlab/pgbouncer')
    end

    it 'installs pgbouncer.ini with default values' do
      # Default values are pulled from:
      # https://github.com/pgbouncer/pgbouncer/blob/6ef66f0139b9c8a5c0747f2a6157d008b87bf0c5/etc/pgbouncer.ini
      expect(chef_run).to render_file(pgbouncer_ini).with_content { |content|
        expect(content).to match(/^listen_addr = 0\.0\.0\.0$/)
        expect(content).to match(/^listen_port = 6432$/)
        expect(content).to match(/^pool_mode = transaction$/)
        expect(content).to match(/^server_reset_query = DISCARD ALL$/)
        expect(content).to match(/^application_name_add_host = 1$/)
        expect(content).to match(/^max_client_conn = 2048$/)
        expect(content).to match(/^default_pool_size = 100$/)
        expect(content).to match(/^min_pool_size = 0$/)
        expect(content).to match(/^reserve_pool_size = 5$/)
        expect(content).to match(/^reserve_pool_timeout = 5.0$/)
        expect(content).to match(/^server_round_robin = 0$/)
        expect(content).to match(/^auth_type = md5$/)
        expect(content).to match(/^log_connections = 0/)
        expect(content).to match(/^server_idle_timeout = 30.0$/)
        expect(content).to match(/^dns_max_ttl = 15.0$/)
        expect(content).to match(/^dns_zone_check_period = 0$/)
        expect(content).to match(/^dns_nxdomain_ttl = 15.0$/)
        expect(content).to match(%r{^auth_file = /var/opt/gitlab/pgbouncer/pg_auth$})
        expect(content).to match(/^admin_users = gitlab-psql, postgres, pgbouncer$/)
        expect(content).to match(/^stats_users = gitlab-psql, postgres, pgbouncer$/)
        expect(content).to match(/^ignore_startup_parameters = extra_float_digits$/)
        expect(content).to match(%r{^unix_socket_dir = /var/opt/gitlab/pgbouncer$})
        expect(content).to match(%r{^%include /var/opt/gitlab/pgbouncer/databases.ini})
        expect(content).to match(/^unix_socket_mode = 0777$/)
        expect(content).to match(/^client_tls_sslmode = disable$/)
        expect(content).to match(/^client_tls_protocols = all$/)
        expect(content).to match(/^client_tls_dheparams = auto$/)
        expect(content).to match(/^client_tls_ecdhcurve = auto$/)
        expect(content).to match(/^server_tls_sslmode = disable$/)
        expect(content).to match(/^server_tls_protocols = all$/)
        expect(content).to match(/^server_tls_ciphers = fast$/)
        expect(content).to match(/^server_reset_query_always = 0$/)
        expect(content).to match(/^server_check_query = select 1$/)
        expect(content).to match(/^server_check_delay = 30$/)
        expect(content).to match(/^syslog = 0$/)
        expect(content).to match(/^syslog_facility = daemon$/)
        expect(content).to match(/^syslog_ident = pgbouncer$/)
        expect(content).to match(/^log_disconnections = 1$/)
        expect(content).to match(/^log_pooler_errors = 1$/)
        expect(content).to match(/^stats_period = 60$/)
        expect(content).to match(/^verbose = 0$/)
        expect(content).to match(/^server_lifetime = 3600$/)
        expect(content).to match(/^server_connect_timeout = 15$/)
        expect(content).to match(/^server_login_retry = 15$/)
        expect(content).to match(/^query_timeout = 0$/)
        expect(content).to match(/^query_wait_timeout = 120$/)
        expect(content).to match(/^client_idle_timeout = 0$/)
        expect(content).to match(/^client_login_timeout = 60$/)
        expect(content).to match(/^autodb_idle_timeout = 3600$/)
        expect(content).to match(/^suspend_timeout = 10$/)
        expect(content).to match(/^idle_transaction_timeout = 0$/)
        expect(content).to match(/^pkt_buf = 4096$/)
        expect(content).to match(/^listen_backlog = 128$/)
        expect(content).to match(/^sbuf_loopcnt = 5$/)
        expect(content).to match(/^max_packet_size = 2147483647$/)
        expect(content).to match(/^tcp_defer_accept = 0$/)
        expect(content).to match(/^tcp_socket_buffer = 0$/)
        expect(content).to match(/^tcp_keepalive = 1$/)
        expect(content).to match(/^tcp_keepcnt = 0$/)
        expect(content).to match(/^tcp_keepidle = 0$/)
        expect(content).to match(/^tcp_keepintvl = 0$/)
        expect(content).to match(/^disable_pqexec = 0$/)
        expect(content).not_to match(/^logfile =/)
        expect(content).not_to match(/^pidfile =/)
        expect(content).not_to match(%r{^unix_socket_group =})
        expect(content).not_to match(%r{^client_tls_ca_file =})
        expect(content).not_to match(%r{^client_tls_cert_file =})
        expect(content).not_to match(%r{^server_tls_ca_file =})
        expect(content).not_to match(%r{^server_tls_key_file =})
        expect(content).not_to match(%r{^server_tls_cert_file =})
        expect(content).not_to match(%r{^max_db_connections =})
        expect(content).not_to match(%r{^max_user_connections =})
      }
    end

    context 'pgbouncer.ini template changes' do
      let(:template) { chef_run.template(pgbouncer_ini) }

      it 'stores the socket directory in a different location when set' do
        stub_gitlab_rb(
          pgbouncer: {
            enable: true,
            unix_socket_dir: '/fake/dir',
            unix_socket_group: 'fakegroup',
            client_tls_ca_file: '/fakecafile',
            client_tls_cert_file: '/fakecertfile',
            server_tls_ca_file: '/fakeservercafile',
            server_tls_key_file: '/fakeserverkeyfile',
            server_tls_cert_file: '/fakeservercertfile',
            max_db_connections: 99999,
            max_user_connections: 88888
          }
        )
        expect(chef_run).to render_file(pgbouncer_ini).with_content { |content|
          expect(content).to match(%r{^unix_socket_dir = /fake/dir$})
          expect(content).to match(%r{^unix_socket_group = fakegroup$})
          expect(content).to match(%r{^client_tls_ca_file = /fakecafile$})
          expect(content).to match(%r{^client_tls_cert_file = /fakecertfile$})
          expect(content).to match(%r{^server_tls_ca_file = /fakeservercafile$})
          expect(content).to match(%r{^server_tls_key_file = /fakeserverkeyfile$})
          expect(content).to match(%r{^server_tls_cert_file = /fakeservercertfile$})
          expect(content).to match(%r{^max_db_connections = 99999$})
          expect(content).to match(%r{^max_user_connections = 88888$})
        }
      end

      it 'reloads pgbouncer and starts pgbouncer if it is not running' do
        allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
        allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('pgbouncer').and_return(true)
        expect(template).to notify('execute[reload pgbouncer]').to(:run).immediately
      end
    end

    context 'databases.json' do
      it 'creates databases.json' do
        expect(chef_run).to create_file(databases_json)
          .with_content("{\"gitlabhq_production\":{\"host\":\"1.2.3.4\"}}")
          .with(user: 'root', group: 'gitlab-psql')
      end

      it 'notifies pgb-notify to generate databases.ini' do
        json_resource = chef_run.file(databases_json)
        expect(json_resource).to notify('execute[generate databases.ini]').to(:run).immediately
      end

      it 'does not run pgb-notify when databases.ini exists' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/var/opt/gitlab/pgbouncer/databases.ini').and_return(true)
        expect(chef_run).not_to run_execute('generate databases.ini')
      end

      it 'stores in a different location when attribute is set' do
        stub_gitlab_rb(
          pgbouncer: {
            enable: true,
            databases_json: '/fakepath/fakedatabases.json'
          }
        )
        expect(chef_run).to create_file('databases.json')
          .with(path: '/fakepath/fakedatabases.json')
      end

      it 'changes the user when the attribute is changed' do
        stub_gitlab_rb(
          pgbouncer: {
            enable: true,
            databases_ini_user: 'fakeuser'
          }
        )
        expect(chef_run).to create_file('databases.json')
          .with(user: 'fakeuser', group: 'gitlab-psql')
      end
    end
  end

  context 'authentication' do
    let(:pg_auth) { '/var/opt/gitlab/pgbouncer/pg_auth' }

    it 'sets up auth_hba when attributes are set' do
      stub_gitlab_rb(
        {
          pgbouncer: {
            enable: true,
            auth_hba_file: '/fake/hba_file',
            auth_query: 'SELECT * FROM FAKETABLE'
          }
        }
      )
      expect(chef_run).to render_file(pgbouncer_ini).with_content { |content|
        expect(content).to match(%r{^auth_hba_file = /fake/hba_file$})
        expect(content).to match(/^auth_query = SELECT \* FROM FAKETABLE$/)
      }
    end

    it 'does not create the user file by default' do
      expect(chef_run).not_to render_file(pg_auth)
    end

    it 'creates the user file when the attributes are set' do
      stub_gitlab_rb(
        {
          pgbouncer: {
            enable: true,
            databases: {
              gitlabhq_production: {
                password: 'fakemd5password',
                user: 'fakeuser',
                host: '127.0.0.1',
                port: 5432
              }
            }
          }
        }
      )
      expect(chef_run).to render_file(pg_auth)
        .with_content(%r{^"fakeuser" "md5fakemd5password"$})
    end

    it 'creates arbitrary user' do
      stub_gitlab_rb(
        {
          pgbouncer: {
            enable: true,
            users: {
              'fakeuser': {
                'password': 'fakehash'
              }
            }
          }
        }
      )
      expect(chef_run).to render_file(pg_auth)
        .with_content(%r{^"fakeuser" "md5fakehash"})
    end

    it 'supports SCRAM secrets' do
      stub_gitlab_rb(
        pgbouncer: {
          enable: true,
          auth_type: 'scram-sha-256',
          users: {
            'fakeuser': {
              'password': 'REALLYFAKEHASH'
            }
          }
        }
      )
      expect(chef_run).to render_file(pg_auth)
        .with_content(%r{^"fakeuser" "SCRAM-SHA-256\$REALLYFAKEHASH"})
    end

    it 'supports a default auth type' do
      stub_gitlab_rb(
        pgbouncer: {
          enable: true,
          auth_type: 'scram-sha-256',
          users: {
            'firstfakeuser': {
              'password': 'AREALLYFAKEHASH'
            },
            'secondfakeuser': {
              'password': 'ANOTHERREALLYFAKEHASH'
            }
          },
          databases: {
            fakedb: {
              user: 'databasefakeuser',
              password: 'DATABASEHASH'
            }
          }
        }
      )
      expect(chef_run).to render_file(pg_auth).with_content { |content|
        expect(content).to match(%r{^"firstfakeuser" "SCRAM-SHA-256\$AREALLYFAKEHASH"})
        expect(content).to match(%r{^"secondfakeuser" "SCRAM-SHA-256\$ANOTHERREALLYFAKEHASH"})
        expect(content).to match(%r{^"databasefakeuser" "SCRAM-SHA-256\$DATABASEHASH"})
      }
    end

    it 'supports per user auth types' do
      stub_gitlab_rb(
        pgbouncer: {
          enable: true,
          users: {
            'firstfakeuser': {
              'password': 'AREALLYFAKEHASH'
            },
            'secondfakeuser': {
              'password': 'ANOTHERREALLYFAKEHASH',
              'auth_type': 'scram-sha-256'
            }
          },
          databases: {
            fakedb: {
              user: 'databasefakeuser',
              auth_type: 'plain',
              password: 'DATABASEHASH'
            }
          }
        }
      )
      expect(chef_run).to render_file(pg_auth).with_content { |content|
        expect(content).to match(%r{^"firstfakeuser" "md5AREALLYFAKEHASH"})
        expect(content).to match(%r{^"secondfakeuser" "SCRAM-SHA-256\$ANOTHERREALLYFAKEHASH"})
        expect(content).to match(%r{^"databasefakeuser" "DATABASEHASH"})
      }
    end

    context 'when disabled by default' do
      it_behaves_like 'disabled runit service', 'pgbouncer'

      it 'includes the pgbouncer_disable recipe' do
        expect(chef_run).to include_recipe('pgbouncer::disable')
      end
    end
  end
end

RSpec.describe 'gitlab-ee::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      {
        pgbouncer: {
          db_user_password: 'fakeuserpassword'
        },
        postgresql: {
          pgbouncer_user: 'fakeuser',
          pgbouncer_user_password: 'fakeuserpassword'
        }
      }
    )
  end

  it 'should create the pgbouncer user on the database' do
    expect(chef_run).to include_recipe('pgbouncer::user')
    expect(chef_run).to create_pgbouncer_user('rails').with(
      password: 'fakeuserpassword'
    )
  end
end
