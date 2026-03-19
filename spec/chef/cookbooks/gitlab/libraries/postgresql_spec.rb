require 'chef_helper'

RSpec.describe Postgresql do
  let(:chef_run) { converge_config }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.parse_variables' do
    context 'when registry database configuration is set' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              user: 'custom_registry_user',
              dbname: 'custom_registry_db',
              password: 'custom_password',
              port: 5433,
              sslmode: 'require'
            }
          }
        )
      end

      it 'sets postgresql registry database configuration based on registry settings' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['dbname']).to eq('custom_registry_db')
        expect(Gitlab['postgresql']['registry']['user']).to eq('custom_registry_user')
        expect(Gitlab['postgresql']['registry']['password']).to eq(Digest::MD5.hexdigest("custom_passwordcustom_registry_user"))
        expect(Gitlab['postgresql']['registry']['port']).to eq(5433)
        expect(Gitlab['postgresql']['registry']['sslmode']).to eq('require')
      end
    end

    context 'when registry database configuration is partially set' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              user: 'custom_registry_user',
              dbname: 'custom_registry_db'
              # port and sslmode not set
            }
          }
        )
      end

      it 'uses registry settings for available values and falls back to node defaults' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['dbname']).to eq('custom_registry_db')
        expect(Gitlab['postgresql']['registry']['user']).to eq('custom_registry_user')
        expect(Gitlab['postgresql']['registry']['password']).to be_nil
        expect(Gitlab['postgresql']['registry']['port']).to eq(5432) # Falls back to node default
        expect(Gitlab['postgresql']['registry']['sslmode']).to eq('prefer') # Falls back to node default
      end
    end

    context 'when registry database configuration is empty' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {}
          }
        )
      end

      it 'uses node defaults for all values' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['dbname']).to eq('registry')
        expect(Gitlab['postgresql']['registry']['user']).to eq('registry')
        expect(Gitlab['postgresql']['registry']['password']).to be_nil
      end
    end

    context 'when postgresql registry configuration already exists' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              user: 'registry_user_from_registry',
              dbname: 'registry_db_from_registry'
            }
          },
          postgresql: {
            registry: {
              user: 'existing_postgresql_user',
              dbname: 'existing_postgresql_db'
            }
          }
        )
      end

      it 'does not override existing postgresql registry configuration' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['user']).to eq('existing_postgresql_user')
        expect(Gitlab['postgresql']['registry']['dbname']).to eq('existing_postgresql_db')
      end
    end

    context 'when postgresql registry password already exists' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              user: 'custom_registry_user',
              password: 'new_password'
            }
          },
          postgresql: {
            registry: {
              password: 'existing_password_hash'
            }
          }
        )
      end

      it 'does not override existing postgresql registry password' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['password']).to eq('existing_password_hash')
      end
    end

    context 'when registry database password is set without explicit user' do
      before do
        stub_gitlab_rb(
          registry: {
            database: {
              password: 'db_password'
            }
          }
        )
      end

      it 'hashes password using node default username' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['postgresql']['registry']['password']).to eq(Digest::MD5.hexdigest('db_passwordregistry'))
      end
    end

    context 'backup/restore username and password precedence' do
      context 'when gitlab_rails credentials are configured' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              backup_registry_user: 'rails_backup_user',
              backup_registry_password: 'rails_backup_pass',
              restore_registry_user: 'rails_restore_user',
              restore_registry_password: 'rails_restore_pass'
            }
          )
        end

        it 'uses gitlab_rails values and hashes passwords with MD5' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('rails_backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to eq(Digest::MD5.hexdigest('rails_backup_passrails_backup_user'))
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('rails_restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to eq(Digest::MD5.hexdigest('rails_restore_passrails_restore_user'))
        end
      end

      context 'when only postgresql.registry credentials are configured' do
        before do
          stub_gitlab_rb(
            postgresql: {
              registry: {
                database_backup_username: 'psql_backup_user',
                database_backup_password: 'psql_backup_pass',
                database_restore_username: 'psql_restore_user',
                database_restore_password: 'psql_restore_pass'
              }
            }
          )
        end

        it 'falls back to postgresql.registry values' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('psql_backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to eq(Digest::MD5.hexdigest('psql_backup_passpsql_backup_user'))
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('psql_restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to eq(Digest::MD5.hexdigest('psql_restore_passpsql_restore_user'))
        end
      end

      context 'when both gitlab_rails and postgresql.registry credentials are configured' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              backup_registry_user: 'rails_backup_user',
              backup_registry_password: 'rails_backup_pass',
              restore_registry_user: 'rails_restore_user',
              restore_registry_password: 'rails_restore_pass'
            },
            postgresql: {
              registry: {
                database_backup_username: 'psql_backup_user',
                database_backup_password: 'psql_backup_pass',
                database_restore_username: 'psql_restore_user',
                database_restore_password: 'psql_restore_pass'
              }
            }
          )
        end

        it 'gitlab_rails takes priority over postgresql.registry' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('rails_backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to eq(Digest::MD5.hexdigest('rails_backup_passrails_backup_user'))
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('rails_restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to eq(Digest::MD5.hexdigest('rails_restore_passrails_restore_user'))
        end
      end

      context 'when gitlab_rails has username but postgresql.registry has password' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              backup_registry_user: 'rails_backup_user',
              restore_registry_user: 'rails_restore_user'
            },
            postgresql: {
              registry: {
                database_backup_password: 'psql_backup_pass',
                database_restore_password: 'psql_restore_pass'
              }
            }
          )
        end

        it 'uses username from gitlab_rails and password from postgresql.registry' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('rails_backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to eq(Digest::MD5.hexdigest('psql_backup_passrails_backup_user'))
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('rails_restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to eq(Digest::MD5.hexdigest('psql_restore_passrails_restore_user'))
        end
      end

      context 'when no credentials are configured' do
        before do
          stub_gitlab_rb({})
        end

        it 'uses node default usernames with nil passwords' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('registry_backup')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to be_nil
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('registry_restore')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to be_nil
        end
      end

      context 'when passwords are empty strings' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              backup_registry_user: 'backup_user',
              backup_registry_password: '',
              restore_registry_user: 'restore_user',
              restore_registry_password: ''
            }
          )
        end

        it 'hashes empty string passwords with MD5' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to eq(Digest::MD5.hexdigest('backup_user'))
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to eq(Digest::MD5.hexdigest('restore_user'))
        end
      end

      context 'when only usernames are configured without passwords' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              backup_registry_user: 'custom_backup_user',
              restore_registry_user: 'custom_restore_user'
            }
          )
        end

        it 'sets usernames without password hashes' do
          Gitlab[:node] = chef_run.node

          expect(Gitlab['postgresql']['registry']['database_backup_username']).to eq('custom_backup_user')
          expect(Gitlab['postgresql']['registry']['database_backup_password']).to be_nil
          expect(Gitlab['postgresql']['registry']['database_restore_username']).to eq('custom_restore_user')
          expect(Gitlab['postgresql']['registry']['database_restore_password']).to be_nil
        end
      end
    end
  end
end
