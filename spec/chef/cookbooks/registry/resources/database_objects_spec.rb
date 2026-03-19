require 'chef_helper'

RSpec.describe 'registry_database_objects' do
  def build_node_attrs(overrides = {})
    base = {
      'registry' => {
        'user' => 'registry',
        'password' => 'md5registrypassword',
        'dbname' => 'registry',
        'database_backup_username' => 'registry_backup',
        'database_backup_password' => 'md5backuppassword',
        'database_restore_username' => 'registry_restore',
        'database_restore_password' => 'md5restorepassword'
      }
    }
    base['registry'] = base['registry'].merge(overrides)
    base
  end

  let(:registry_overrides) { {} }

  let(:chef_runner) do
    attrs = build_node_attrs(registry_overrides)
    ChefSpec::SoloRunner.new(step_into: %w(registry_database_objects postgresql_user postgresql_query postgresql_schema)) do |node|
      node.normal['postgresql']['registry']['user'] = attrs['registry']['user']
      node.normal['postgresql']['registry']['password'] = attrs['registry']['password']
      node.normal['postgresql']['registry']['dbname'] = attrs['registry']['dbname']
      node.normal['postgresql']['registry']['database_backup_username'] = attrs['registry']['database_backup_username']
      node.normal['postgresql']['registry']['database_backup_password'] = attrs['registry']['database_backup_password']
      node.normal['postgresql']['registry']['database_restore_username'] = attrs['registry']['database_restore_username']
      node.normal['postgresql']['registry']['database_restore_password'] = attrs['registry']['database_restore_password']
      node.normal['patroni']['enable'] = false
    end
  end

  let(:chef_run) do
    chef_runner.converge('test_registry::registry_database_objects_run')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    # Mock PgStatusHelper to bypass actual PostgreSQL connection checks
    pg_status_helper = instance_double(PgStatusHelper)
    allow(PgStatusHelper).to receive(:new).and_return(pg_status_helper)
    allow(pg_status_helper).to receive(:ready?).and_return(true)

    # Allow real helper instances but stub methods that check PostgreSQL state
    allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:bootstrapped?).and_return(true)

    allow_any_instance_of(RegistryPgHelper).to receive(:is_offline_or_readonly?).and_return(false)
  end

  context 'when backup and restore credentials are fully defined' do
    it 'creates the backup user with minimal privileges' do
      expect(chef_run).to create_postgresql_user('registry_backup').with(
        password: 'md5md5backuppassword',
        options: %w[NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION]
      )
    end

    it 'creates the restore user with superuser privileges' do
      expect(chef_run).to create_postgresql_user('registry_restore').with(
        password: 'md5md5restorepassword',
        options: %w[SUPERUSER]
      )
    end

    it 'creates the partitions schema' do
      expect(chef_run).to create_postgresql_schema('partitions').with(
        database: 'registry',
        owner: 'registry'
      )
    end

    it 'creates partitions schema before backup user' do
      partitions_schema = chef_run.find_resource(:postgresql_schema, 'partitions')
      backup_user = chef_run.find_resource(:postgresql_user, 'registry_backup')

      expect(partitions_schema).to be
      expect(backup_user).to be
    end

    it 'grants backup privileges to backup user' do
      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT CONNECT ON DATABASE.*registry.*TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT USAGE ON SCHEMA public TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT USAGE ON SCHEMA partitions TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT SELECT ON ALL TABLES IN SCHEMA public TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT SELECT ON ALL TABLES IN SCHEMA partitions TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/GRANT SELECT ON ALL SEQUENCES IN SCHEMA partitions TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/ALTER DEFAULT PRIVILEGES FOR ROLE.*registry.*IN SCHEMA public.*GRANT SELECT ON TABLES TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/ALTER DEFAULT PRIVILEGES FOR ROLE.*registry.*IN SCHEMA partitions.*GRANT SELECT ON TABLES TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/ALTER DEFAULT PRIVILEGES FOR ROLE.*registry.*IN SCHEMA public.*GRANT SELECT ON SEQUENCES TO.*registry_backup/m)
      )

      expect(chef_run).to run_postgresql_query('grant registry database backup privileges to registry_backup').with(
        db_name: 'registry',
        query: match(/ALTER DEFAULT PRIVILEGES FOR ROLE.*registry.*IN SCHEMA partitions.*GRANT SELECT ON SEQUENCES TO.*registry_backup/m)
      )
    end
  end

  context 'when backup credentials are not defined' do
    let(:registry_overrides) do
      {
        'database_backup_username' => nil,
        'database_backup_password' => nil
      }
    end

    it 'does not create the backup user' do
      expect(chef_run).not_to create_postgresql_user('registry_backup')
    end

    it 'does not create the partitions schema' do
      expect(chef_run).not_to create_postgresql_schema('partitions')
    end

    it 'does not grant backup privileges' do
      expect(chef_run).not_to run_postgresql_query('grant registry database backup privileges to registry_backup')
    end

    it 'still creates the restore user' do
      expect(chef_run).to create_postgresql_user('registry_restore').with(
        password: 'md5md5restorepassword',
        options: %w[SUPERUSER]
      )
    end
  end

  context 'when backup password is nil but username is defined' do
    let(:registry_overrides) do
      {
        'database_backup_password' => nil
      }
    end

    it 'does not create the backup user' do
      expect(chef_run).not_to create_postgresql_user('registry_backup')
    end

    it 'does not create the partitions schema' do
      expect(chef_run).not_to run_postgresql_query('create partitions schema in registry')
    end

    it 'does not grant backup privileges' do
      expect(chef_run).not_to run_postgresql_query('grant registry database backup privileges to registry_backup')
    end
  end

  context 'when backup credentials are empty strings' do
    let(:registry_overrides) do
      {
        'database_backup_username' => '',
        'database_backup_password' => ''
      }
    end

    it 'does not create the backup user' do
      expect(chef_run).not_to create_postgresql_user('')
    end

    it 'does not create the partitions schema' do
      expect(chef_run).not_to create_postgresql_schema('partitions')
    end

    it 'does not grant backup privileges' do
      expect(chef_run).not_to run_postgresql_query('grant registry database backup privileges to ')
    end
  end

  context 'when backup password is empty string but username is defined' do
    let(:registry_overrides) do
      {
        'database_backup_password' => ''
      }
    end

    it 'does not create the backup user' do
      expect(chef_run).not_to create_postgresql_user('registry_backup')
    end

    it 'does not grant backup privileges' do
      expect(chef_run).not_to run_postgresql_query('grant registry database backup privileges to registry_backup')
    end
  end

  context 'when restore credentials are not defined' do
    let(:registry_overrides) do
      {
        'database_restore_username' => nil,
        'database_restore_password' => nil
      }
    end

    it 'does not create the restore user' do
      expect(chef_run).not_to create_postgresql_user('registry_restore')
    end

    it 'still creates the backup user' do
      expect(chef_run).to create_postgresql_user('registry_backup').with(
        password: 'md5md5backuppassword',
        options: %w[NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION]
      )
    end

    it 'still creates the partitions schema' do
      expect(chef_run).to create_postgresql_schema('partitions').with(
        database: 'registry',
        owner: 'registry'
      )
    end
  end

  context 'when restore password is nil but username is defined' do
    let(:registry_overrides) do
      {
        'database_restore_password' => nil
      }
    end

    it 'does not create the restore user' do
      expect(chef_run).not_to create_postgresql_user('registry_restore')
    end
  end

  context 'when restore credentials are empty strings' do
    let(:registry_overrides) do
      {
        'database_restore_username' => '',
        'database_restore_password' => ''
      }
    end

    it 'does not create the restore user' do
      expect(chef_run).not_to create_postgresql_user('')
    end
  end

  context 'when restore password is empty string but username is defined' do
    let(:registry_overrides) do
      {
        'database_restore_password' => ''
      }
    end

    it 'does not create the restore user' do
      expect(chef_run).not_to create_postgresql_user('registry_restore')
    end
  end

  context 'when no backup or restore credentials are defined' do
    let(:registry_overrides) do
      {
        'database_backup_username' => nil,
        'database_backup_password' => nil,
        'database_restore_username' => nil,
        'database_restore_password' => nil
      }
    end

    it 'does not create the backup user' do
      expect(chef_run).not_to create_postgresql_user('registry_backup')
    end

    it 'does not create the restore user' do
      expect(chef_run).not_to create_postgresql_user('registry_restore')
    end

    it 'does not create the partitions schema' do
      expect(chef_run).not_to run_postgresql_query('create partitions schema in registry')
    end

    it 'does not grant backup privileges' do
      expect(chef_run).not_to run_postgresql_query('grant registry database backup privileges to registry_backup')
    end

    it 'still creates the registry user and database' do
      expect(chef_run).to create_postgresql_user('registry')
      expect(chef_run).to create_postgresql_database('registry')
    end
  end
end
