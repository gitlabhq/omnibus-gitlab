require 'chef_helper'

RSpec.describe 'gitlab::registry_enable_backup_restore_credentials' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_enable))
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      gitlab_rails: { backup_role: true }
    )
  end

  context 'backup credentials directory and files' do
    it 'creates backup credentials directory with correct permissions' do
      expect(chef_run).to create_directory('/opt/gitlab/etc/gitlab-backup/env').with(
        owner: 'root',
        group: 'root',
        mode: '0750',
        recursive: true
      )
    end

    context 'when connection variables are configured' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_role: true,
            backup_registry: {
              database_connection: {
                host: 'localhost',
                port: 5432,
                dbname: 'registry_db',
                sslmode: 'require',
                sslcert: '/path/to/cert.pem',
                sslkey: '/path/to/key.pem',
                sslrootcert: '/path/to/root.pem'
              }
            }
          }
        )
      end

      it 'creates connection environment file with database settings' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-connection').with(
          source: 'registry-env-db_connection.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            database_host: 'localhost',
            database_port: 5432,
            database_name: 'registry_db',
            database_sslmode: 'require',
            database_sslcert: '/path/to/cert.pem',
            database_sslkey: '/path/to/key.pem',
            database_sslrootcert: '/path/to/root.pem'
          }
        )
      end
    end

    context 'when backup user credentials are provided' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_role: true,
            backup_registry_user: 'backup_user',
            backup_registry_password: 'backup_secret'
          }
        )
      end

      it 'creates backup user environment file with credentials' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-backup_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'backup_user',
            password: 'backup_secret'
          }
        )
      end
    end

    context 'when backup user credentials are not provided' do
      it 'creates backup user environment file with default username only' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-backup_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'registry_backup',
            password: nil
          }
        )
      end
    end

    context 'when backup user is provided but password is empty' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_role: true,
            backup_registry_user: 'backup_user',
            backup_registry_password: ''
          }
        )
      end

      it 'creates backup user environment file with username only' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-backup_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'backup_user',
            password: ''
          }
        )
      end
    end

    context 'when restore user credentials are provided' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_role: true,
            restore_registry_user: 'restore_user',
            restore_registry_password: 'restore_secret'
          }
        )
      end

      it 'creates restore user environment file with credentials' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-restore_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'restore_user',
            password: 'restore_secret'
          }
        )
      end
    end

    context 'when restore user credentials are not provided' do
      it 'creates restore user environment file with default username only' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-restore_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'registry_restore',
            password: nil
          }
        )
      end
    end

    context 'when restore user is provided but password is empty' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_role: true,
            restore_registry_user: 'restore_user',
            restore_registry_password: ''
          }
        )
      end

      it 'creates restore user environment file with username only' do
        expect(chef_run).to create_template('/opt/gitlab/etc/gitlab-backup/env/env-restore_user').with(
          source: 'registry-env-db_user.erb',
          owner: 'root',
          group: 'root',
          mode: '0400',
          sensitive: true,
          variables: {
            username: 'restore_user',
            password: ''
          }
        )
      end
    end
  end
end
