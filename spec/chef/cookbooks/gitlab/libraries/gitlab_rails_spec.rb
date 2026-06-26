require 'chef_helper'

RSpec.describe GitlabRails do
  let(:chef_run) { converge_config }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.registry_connection_variables' do
    let(:chef_run) { converge_config }

    before do
      stub_gitlab_rb(
        gitlab_rails: {
          backup_registry: {
            database_connection: {
              host: 'db.example.com',
              port: 5433,
              dbname: 'custom_registry',
              sslmode: 'require',
              sslcert: '/path/to/cert.pem',
              sslkey: '/path/to/key.pem',
              sslrootcert: '/path/to/root.pem'
            }
          }
        }
      )
    end

    it 'returns hash with all connection variables' do
      Gitlab[:node] = chef_run.node

      expect(described_class.registry_connection_variables).to eq(
        database_host: 'db.example.com',
        database_port: 5433,
        database_name: 'custom_registry',
        database_sslmode: 'require',
        database_sslcert: '/path/to/cert.pem',
        database_sslkey: '/path/to/key.pem',
        database_sslrootcert: '/path/to/root.pem'
      )
    end
  end

  describe '.backup_user_variables' do
    let(:chef_run) { converge_config }

    before do
      stub_gitlab_rb(
        gitlab_rails: {
          backup_registry_user: 'backup_user',
          backup_registry_password: 'backup_secret'
        }
      )
    end

    it 'returns hash with backup user credentials' do
      Gitlab[:node] = chef_run.node

      expect(described_class.backup_user_variables).to eq(
        username: 'backup_user',
        password: 'backup_secret'
      )
    end
  end

  describe '.restore_user_variables' do
    let(:chef_run) { converge_config }

    before do
      stub_gitlab_rb(
        gitlab_rails: {
          restore_registry_user: 'restore_user',
          restore_registry_password: 'restore_secret'
        }
      )
    end

    it 'returns hash with restore user credentials' do
      Gitlab[:node] = chef_run.node

      expect(described_class.restore_user_variables).to eq(
        username: 'restore_user',
        password: 'restore_secret'
      )
    end
  end

  describe '.parse_registry_postgresql_settings' do
    context 'when registry.database is fully configured' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              host: 'reg-db.example.com',
              port: 5433,
              dbname: 'custom_registry',
              sslmode: 'require',
              sslcert: '/path/to/cert.pem',
              sslkey: '/path/to/key.pem',
              sslrootcert: '/path/to/root.pem'
            }
          }
        )
      end

      it 'uses registry.database values' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        expect(db_conn['host']).to eq('reg-db.example.com')
        expect(db_conn['port']).to eq(5433)
        expect(db_conn['dbname']).to eq('custom_registry')
        expect(db_conn['sslmode']).to eq('require')
        expect(db_conn['sslcert']).to eq('/path/to/cert.pem')
        expect(db_conn['sslkey']).to eq('/path/to/key.pem')
        expect(db_conn['sslrootcert']).to eq('/path/to/root.pem')
      end
    end

    context 'when only gitlab_rails.backup_registry.database_connection is configured' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_registry: {
              database_connection: {
                host: 'rails-db.example.com',
                port: 5434,
                dbname: 'rails_registry',
                sslmode: 'verify-full'
              }
            }
          }
        )
      end

      it 'uses gitlab_rails.backup_registry.database_connection values' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        expect(db_conn['host']).to eq('rails-db.example.com')
        expect(db_conn['port']).to eq(5434)
        expect(db_conn['dbname']).to eq('rails_registry')
        expect(db_conn['sslmode']).to eq('verify-full')
      end
    end

    context 'when both registry.database and gitlab_rails.backup_registry.database_connection are configured' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              host: 'reg-db.example.com',
              port: 5433,
              dbname: 'reg_db',
              sslmode: 'require'
            }
          },
          gitlab_rails: {
            backup_registry: {
              database_connection: {
                host: 'rails-db.example.com',
                port: 5434,
                dbname: 'rails_db',
                sslmode: 'verify-full'
              }
            }
          }
        )
      end

      it 'registry.database takes priority over gitlab_rails.backup_registry.database_connection' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        expect(db_conn['host']).to eq('reg-db.example.com')
        expect(db_conn['port']).to eq(5433)
        expect(db_conn['dbname']).to eq('reg_db')
        expect(db_conn['sslmode']).to eq('require')
      end
    end

    context 'when registry.database is partially configured and gitlab_rails fills the rest' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              host: 'reg-db.example.com'
            }
          },
          gitlab_rails: {
            backup_registry: {
              database_connection: {
                port: 5434,
                sslmode: 'verify-full',
                sslcert: '/path/to/cert.pem'
              }
            }
          }
        )
      end

      it 'merges values from both sources with registry.database taking priority' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        expect(db_conn['host']).to eq('reg-db.example.com')
        expect(db_conn['port']).to eq(5434)
        expect(db_conn['sslmode']).to eq('verify-full')
        expect(db_conn['sslcert']).to eq('/path/to/cert.pem')
      end
    end

    context 'when backup_registry.database_connection is partially configured with registry.database providing overrides' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              enabled: true,
              user: 'registry_user',
              password: '51pp7hFYmgsl14rB95flz9uSdGGi12hn',
              dbname: 'registry_db',
              auto_create: true
            }
          },
          gitlab_rails: {
            backup_registry: {
              database_connection: {
                port: 5434,
                sslcert: '/custom/cert.pem'
              }
            }
          }
        )
      end

      it 'merges registry.database, partial database_connection, and node defaults' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        # dbname from registry.database (priority 1) overrides node defaults
        expect(db_conn['dbname']).to eq('registry_db')
        # port from rails_db_config (priority 2) since registry.database has no port
        expect(db_conn['port']).to eq(5434)
        # sslcert from rails_db_config (priority 2) since registry.database has no sslcert
        expect(db_conn['sslcert']).to eq('/custom/cert.pem')
        # sslmode falls through to node['registry']['database'] default (priority 3)
        expect(db_conn['sslmode']).to eq('prefer')
        # host falls through to postgresql dir default (unix socket path)
        expect(db_conn['host']).to eq('/var/opt/gitlab/postgresql')
        expect(db_conn['sslkey']).to be_nil
        expect(db_conn['sslrootcert']).to be_nil
      end
    end

    context 'when nothing is configured' do
      before do
        stub_gitlab_rb({})
      end

      it 'falls back to node defaults' do
        Gitlab[:node] = chef_run.node

        db_conn = Gitlab['gitlab_rails']['backup_registry']['database_connection']
        expect(db_conn['host']).to eq('/var/opt/gitlab/postgresql')
        expect(db_conn['port']).to eq(5432)
        expect(db_conn['dbname']).to eq('registry')
        expect(db_conn['sslmode']).to eq('prefer')
        expect(db_conn['sslcert']).to be_nil
        expect(db_conn['sslkey']).to be_nil
        expect(db_conn['sslrootcert']).to be_nil
      end
    end
  end

  describe '.translate_rails_nginx_settings' do
    let(:chef_run) { converge_config }

    context 'when the rails-nginx enable option is already set by the operator' do
      before do
        stub_gitlab_rb(
          gitlab_rails: { nginx: { enable: false } },
          nginx: { enable: true }
        )
      end

      it 'leaves the rails-nginx enable untouched' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['enable']).to be false
      end
    end

    context 'when neither option is set' do
      before do
        stub_gitlab_rb({})
      end

      # With no service role active, `DefaultRole.load_role` enables the
      # default service group at parse time. `nginx` lives in that group
      # via the `service 'nginx'` registration in `services.rb`, so
      # `node.default['nginx']['enable']` becomes `true` before the
      # translate runs, and the translate carries that through to the
      # rails-nginx option.
      it 'follows the default-group enable for nginx' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['enable']).to be true
      end
    end

    context 'when the operator sets the legacy nginx[enable] = false against an active application role' do
      before do
        stub_gitlab_rb(
          application_role: { enable: true },
          nginx: { enable: false }
        )
      end

      # The application role calls `Services.enable_group('rails')`, which
      # writes `node.default['nginx']['enable'] = true`. The translate must
      # carry the operator-set `false` through anyway; the regression this
      # pins folded the `false` into the role's `true` via `||`.
      it 'preserves the operator-set false on the rails-nginx enable' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['enable']).to be false
      end
    end

    context 'when the operator sets the legacy nginx[enable] = true' do
      before do
        stub_gitlab_rb(nginx: { enable: true })
      end

      it 'propagates the true to the rails-nginx enable' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['enable']).to be true
      end
    end

    context 'when the operator sets a server-and-clients shared nginx[*] key' do
      before do
        stub_gitlab_rb(nginx: { gzip_enabled: false })
        allow(LoggingHelper).to receive(:deprecation)
      end

      # The global `nginx.conf` template reads `node['nginx']['gzip_enabled']`
      # via `nginx/recipes/enable.rb`, so a deprecation that routes operators
      # to `gitlab_rails['nginx']['gzip_enabled']` would orphan the daemon.
      it 'does not emit a deprecation that names the legacy key' do
        Gitlab[:node] = chef_run.node
        expect(LoggingHelper).not_to have_received(:deprecation).with(
          "nginx['gzip_enabled'] has been deprecated. Please use gitlab_rails['nginx']['gzip_enabled'] instead."
        )
      end

      it 'still mirrors the legacy value into the rails-nginx subkey' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['gzip_enabled']).to be false
      end
    end

    context 'when the operator sets nginx[log_directory]' do
      before do
        stub_gitlab_rb(nginx: { log_directory: '/legacy/log' })
        allow(LoggingHelper).to receive(:deprecation)
      end

      # `LogfilesHelper.logging_settings('nginx')` reads
      # `node['nginx']['log_directory']` to feed the runit service log
      # directory and the svlogd path -- routing operators to the rails
      # subkey would orphan the daemon's log path.
      it 'does not emit a deprecation that names the legacy key' do
        Gitlab[:node] = chef_run.node
        expect(LoggingHelper).not_to have_received(:deprecation).with(
          "nginx['log_directory'] has been deprecated. Please use gitlab_rails['nginx']['log_directory'] instead."
        )
      end

      it 'still mirrors the legacy value into the rails-nginx subkey' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['log_directory']).to eq('/legacy/log')
      end
    end

    context 'when the operator sets a clients-only shared nginx[*] key' do
      before do
        stub_gitlab_rb(nginx: { ssl_certificate: '/legacy/path.crt' })
        allow(LoggingHelper).to receive(:deprecation)
      end

      it 'emits a deprecation that names the legacy key' do
        Gitlab[:node] = chef_run.node
        expect(LoggingHelper).to have_received(:deprecation).with(
          "nginx['ssl_certificate'] has been deprecated. Please use gitlab_rails['nginx']['ssl_certificate'] instead."
        )
      end
    end

    context 'when the operator sets a legacy explicit-list key' do
      let(:custom_pages) do
        { '404' => { 'title' => 'Not Found', 'header' => 'h', 'message' => 'm' } }
      end

      before do
        stub_gitlab_rb(nginx: { custom_error_pages: custom_pages })
        allow(LoggingHelper).to receive(:deprecation)
      end

      # Pins the explicit-list iteration against `custom_error_pages`.
      it 'translates the legacy value into the rails-nginx subkey' do
        Gitlab[:node] = chef_run.node
        expect(Gitlab['gitlab_rails']['nginx']['custom_error_pages']).to eq(custom_pages)
      end

      it 'emits a deprecation that names the legacy key' do
        Gitlab[:node] = chef_run.node
        expect(LoggingHelper).to have_received(:deprecation).with(
          "nginx['custom_error_pages'] has been deprecated. Please use gitlab_rails['nginx']['custom_error_pages'] instead."
        )
      end
    end
  end
end
