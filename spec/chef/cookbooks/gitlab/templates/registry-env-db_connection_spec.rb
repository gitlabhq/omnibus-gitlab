require 'chef_helper'

RSpec.describe 'registry-env-db_connection.erb template' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_enable))
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  let(:template_path) { '/opt/gitlab/etc/gitlab-backup/env/env-connection' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(registry_external_url: 'https://registry.example.com')

    # Mock PgStatusHelper to bypass actual PostgreSQL connection checks
    pg_status_helper = instance_double(PgStatusHelper)
    allow(PgStatusHelper).to receive(:new).and_return(pg_status_helper)
    allow(pg_status_helper).to receive(:ready?).and_return(true)

    # Allow real helper instances but stub methods that check PostgreSQL state
    allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:bootstrapped?).and_return(true)

    allow_any_instance_of(RegistryPgHelper).to receive(:is_offline_or_readonly?).and_return(false)
  end

  context 'with all database connection parameters' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true
        },
        registry: {
          database: {
            enabled: true,
            host: 'db.example.com',
            port: 5433,
            dbname: 'custom_registry',
            sslmode: 'require',
            sslcert: '/path/to/client.crt',
            sslkey: '/path/to/client.key',
            sslrootcert: '/path/to/ca.crt'
          }
        }
      )
    end

    it 'renders all database environment variables' do
      expect(chef_run).to render_file(template_path)
        .with_content('REGISTRY_DATABASE_HOST=db.example.com')
        .with_content('REGISTRY_DATABASE_PORT=5433')
        .with_content('REGISTRY_DATABASE_NAME=custom_registry')
        .with_content('REGISTRY_DATABASE_SSLMODE=require')
        .with_content('REGISTRY_DATABASE_SSLCERT=/path/to/client.crt')
        .with_content('REGISTRY_DATABASE_SSLKEY=/path/to/client.key')
        .with_content('REGISTRY_DATABASE_SSLROOTCERT=/path/to/ca.crt')
    end
  end

  context 'with minimal database connection parameters' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true
        },
        registry: {
          database: {
            enabled: true,
            host: 'localhost',
            dbname: 'registry'
          }
        }
      )
    end

    it 'renders only provided environment variables' do
      expect(chef_run).to render_file(template_path).with_content { |content|
        expect(content).to include('REGISTRY_DATABASE_HOST=localhost')
        expect(content).to include('REGISTRY_DATABASE_NAME=registry')
        expect(content).to include('REGISTRY_DATABASE_PORT=5432')
        expect(content).to include('REGISTRY_DATABASE_SSLMODE=prefer')

        expect(content).not_to match(/^REGISTRY_DATABASE_SSLCERT=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLKEY=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLROOTCERT=/)
      }
    end
  end

  context 'with empty database connection parameters' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true
        },
        registry: {
          database: {
            enabled: true,
            host: '',
            port: '',
            dbname: '',
            sslmode: '',
            sslcert: '',
            sslkey: '',
            sslrootcert: ''
          }
        }
      )
    end

    it 'does not render empty environment variables' do
      expect(chef_run).to render_file(template_path).with_content { |content|
        expect(content).not_to match(/^REGISTRY_DATABASE_HOST=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_PORT=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_NAME=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLMODE=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLCERT=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLKEY=/)
        expect(content).not_to match(/^REGISTRY_DATABASE_SSLROOTCERT=/)
      }
    end
  end
end
