require 'chef_helper'

RSpec.describe 'postgresql::managed_databases' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: %w[postgresql_managed_database_objects])
                        .converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:replica?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('16.0'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('16.0'))
    allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('16.0'))
  end

  context 'with no component databases registered' do
    it 'does not create any postgresql_managed_database_objects resource' do
      expect(chef_run.find_resources(:postgresql_managed_database_objects)).to be_empty
    end
  end

  context 'with one component database registered' do
    before do
      stub_gitlab_rb(
        postgresql: {
          component_databases: {
            'gate' => {
              'enable' => true,
              'user' => 'gate',
              'password' => 'secret',
              'extensions' => %w[pg_trgm]
            }
          }
        }
      )
    end

    it 'creates the database, user, and extensions' do
      expect(chef_run).to create_postgresql_managed_database_objects('gate')
      expect(chef_run).to create_postgresql_user('gate')
      expect(chef_run).to create_postgresql_database('gate')
      expect(chef_run).to enable_postgresql_extension('pg_trgm')
    end
  end

  context 'when the node is a Patroni replica' do
    before do
      stub_gitlab_rb(
        postgresql: {
          component_databases: {
            'gate' => { 'enable' => true, 'user' => 'gate', 'password' => 'secret' }
          }
        }
      )
      allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
    end

    it 'does not create the database (guarded by not_if replica?)' do
      expect(chef_run).not_to create_postgresql_database('gate')
    end
  end

  context 'with an explicit owner distinct from user' do
    before do
      stub_gitlab_rb(
        postgresql: {
          component_databases: {
            'gate' => {
              'enable' => true, 'user' => 'gate', 'owner' => 'gate_admin',
              'password' => 'secret'
            }
          }
        }
      )
    end

    it 'creates the database with the explicit owner' do
      expect(chef_run).to create_postgresql_database('gate').with(owner: 'gate_admin')
    end

    it 'creates the owner role so CREATE DATABASE ... OWNER does not fail on a fresh cluster' do
      expect(chef_run).to create_postgresql_user('gate_admin')
    end

    it 'creates the owner role without a password' do
      resource = chef_run.postgresql_user('gate_admin')
      expect(resource.password).to be_nil
    end

    it 'still creates the connect-user with its declared password' do
      expect(chef_run).to create_postgresql_user('gate')
      resource = chef_run.postgresql_user('gate')
      expect(resource.password).to eq("md5#{Digest::MD5.hexdigest('secretgate')}")
    end
  end

  context 'when owner equals user (default)' do
    before do
      stub_gitlab_rb(
        postgresql: {
          component_databases: {
            'gate' => { 'enable' => true, 'user' => 'gate', 'password' => 'secret' }
          }
        }
      )
    end

    it 'creates exactly one postgresql_user resource' do
      users = chef_run.find_resources(:postgresql_user).select { |r| r.name == 'gate' }
      expect(users.size).to eq(1)
    end
  end

  context 'with no password' do
    before do
      stub_gitlab_rb(
        postgresql: {
          component_databases: {
            'gate' => { 'enable' => true, 'user' => 'gate' }
          }
        }
      )
    end

    it 'creates the postgresql user without a password directive' do
      expect(chef_run).to create_postgresql_user('gate')
      resource = chef_run.postgresql_user('gate')
      expect(resource.password).to be_nil
    end
  end
end
