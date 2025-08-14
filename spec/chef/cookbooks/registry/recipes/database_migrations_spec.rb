require 'chef_helper'

RSpec.describe 'registry::database_migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default values (database.enable:false && auto_migrate:true)' do
    before do
      # Test with default values from attributes
      stub_gitlab_rb(registry_external_url: 'https://registry.example.com')
    end

    it 'does not run migrations when database is disabled by default' do
      expect(chef_run).not_to run_registry_database_migrations('registry')
    end
  end

  context 'when database is enabled' do
    let(:database_config) do
      { "enabled" => true }
    end

    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        registry: { database: database_config }
      )
    end

    it 'creates the database migrations resource' do
      expect(chef_run).to run_registry_database_migrations('registry')
    end

    context 'when auto_migrate is disabled' do
      before do
        stub_gitlab_rb(
          registry_external_url: 'https://registry.example.com',
          registry: {
            database: database_config,
            auto_migrate: false
          }
        )
      end

      it 'does not run the database migrations' do
        expect(chef_run).not_to run_registry_database_migrations('registry')
      end
    end
  end
end
