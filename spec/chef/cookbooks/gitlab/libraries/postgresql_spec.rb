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
        expect(Gitlab['postgresql']['registry']['password']).to eq('custom_password')
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
  end
end
