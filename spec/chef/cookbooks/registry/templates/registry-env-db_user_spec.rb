require 'chef_helper'

RSpec.describe 'registry-env-db_user.erb template' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_enable))
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  let(:backup_template_path) { '/opt/gitlab/etc/gitlab-backup/env/env-backup_user' }
  let(:restore_template_path) { '/opt/gitlab/etc/gitlab-backup/env/env-restore_user' }

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

  context 'backup user template with credentials' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          backup_registry_user: 'backup_user',
          backup_registry_password: 'backup_secret'
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'renders backup user environment variables' do
      expect(chef_run).to render_file(backup_template_path)
        .with_content('REGISTRY_DATABASE_USER=backup_user')
        .with_content('REGISTRY_DATABASE_PASSWORD=backup_secret')
    end
  end

  context 'restore user template with credentials' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          restore_registry_user: 'restore_user',
          restore_registry_password: 'restore_secret'
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'renders restore user environment variables' do
      expect(chef_run).to render_file(restore_template_path)
        .with_content('REGISTRY_DATABASE_USER=restore_user')
        .with_content('REGISTRY_DATABASE_PASSWORD=restore_secret')
    end
  end

  context 'with empty restore username' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          restore_registry_user: '',
          restore_registry_password: 'restore_secret'
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'does not create the file when restore username is empty' do
      expect(chef_run).to delete_file(restore_template_path)
    end
  end

  context 'with empty username' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          backup_registry_user: '',
          backup_registry_password: 'backup_secret'
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'does not create the file when username is empty' do
      expect(chef_run).to delete_file(backup_template_path)
    end
  end

  context 'with empty password' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          backup_registry_user: 'backup_user',
          backup_registry_password: ''
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'renders only username when password is empty' do
      expect(chef_run).to render_file(backup_template_path).with_content { |content|
        expect(content).to include('REGISTRY_DATABASE_USER=backup_user')
        expect(content).not_to match(/^REGISTRY_DATABASE_PASSWORD=/)
      }
    end
  end

  context 'with both username and password empty' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        gitlab_rails: {
          backup_role: true,
          backup_registry_user: '',
          backup_registry_password: ''
        },
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'does not create the file when username is empty' do
      expect(chef_run).to delete_file(backup_template_path)
    end
  end
end
