require 'chef_helper'

RSpec.describe 'postgresql_database_access' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_database_access postgresql_role)) do |node|
      node.normal['postgresql']['restrict_database_access'] = restrict
    end
  end
  let(:restrict) { true }
  let(:chef_run) { runner.converge('test_postgresql::postgresql_database_access') }

  before do
    allow_any_instance_of(PgHelper).to receive(:replica?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:is_ready?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    # The connect role already exists (skips creation in the stepped-into
    # postgresql_role resource).
    allow_any_instance_of(PgHelper).to receive(:role_exists?).and_return(true)
    # By default every login role already exists.
    allow_any_instance_of(PgHelper).to receive(:user_exists?).and_return(true)
    # By default every requested schema already exists.
    allow_any_instance_of(PgHelper).to receive(:schema_exists?).and_return(true)
  end

  context 'when restrict_database_access is disabled (default)' do
    let(:restrict) { false }

    it 'does not enforce anything' do
      expect(chef_run.find_resources(:postgresql_query)).to be_empty
      expect(chef_run).not_to create_postgresql_role('gitlabhq_production_connect')
    end
  end

  context 'when enabled and all required roles exist' do
    it 'creates the per-database connect role' do
      expect(chef_run).to create_postgresql_role('gitlabhq_production_connect')
    end

    it 'grants CONNECT and schema USAGE to the connect role' do
      expect(chef_run).to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/GRANT CONNECT ON DATABASE .*gitlabhq_production.* TO .*gitlabhq_production_connect/)
      )
      expect(chef_run).to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/GRANT USAGE ON SCHEMA .*public.* TO .*gitlabhq_production_connect/)
      )
    end

    it 'grants the connect role to the app user and pgbouncer' do
      expect(chef_run).to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/GRANT .*gitlabhq_production_connect.* TO .*gitlab/)
      )
      expect(chef_run).to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/GRANT .*gitlabhq_production_connect.* TO .*pgbouncer/)
      )
    end

    it 'revokes the implicit PUBLIC CONNECT' do
      expect(chef_run).to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/REVOKE CONNECT ON DATABASE .*gitlabhq_production.* FROM PUBLIC/)
      )
    end

    it 'honors additional schemas' do
      expect(chef_run).to run_postgresql_query('restrict database access for custom_schema_db').with(
        query: match(/GRANT USAGE ON SCHEMA .*partitions.* TO .*custom_schema_db_connect/)
      )
    end
  end

  context 'when a requested schema does not exist yet' do
    before do
      allow_any_instance_of(PgHelper).to receive(:schema_exists?) do |_, schema, _db|
        schema != 'partitions'
      end
    end

    it 'skips the USAGE grant for the missing schema' do
      expect(chef_run).not_to run_postgresql_query('restrict database access for custom_schema_db').with(
        query: match(/GRANT USAGE ON SCHEMA .*partitions/)
      )
    end

    it 'still grants USAGE on the schemas that do exist' do
      expect(chef_run).to run_postgresql_query('restrict database access for custom_schema_db').with(
        query: match(/GRANT USAGE ON SCHEMA .*public.* TO .*custom_schema_db_connect/)
      )
    end
  end

  context 'when the pgbouncer role does not exist yet (lockout guard)' do
    before do
      allow_any_instance_of(PgHelper).to receive(:role_exists?) do |_, role|
        role != 'pgbouncer'
      end
    end

    it 'does not grant the connect role to the missing pgbouncer role' do
      expect(chef_run).not_to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/TO .*pgbouncer/)
      )
    end

    it 'defers the REVOKE until pgbouncer exists' do
      expect(chef_run).not_to run_postgresql_query('restrict database access for gitlabhq_production').with(
        query: match(/REVOKE CONNECT/)
      )
    end

    it 'still enforces databases that do not require pgbouncer' do
      expect(chef_run).to run_postgresql_query('restrict database access for no_pgbouncer_db').with(
        query: match(/REVOKE CONNECT ON DATABASE .*no_pgbouncer_db.* FROM PUBLIC/)
      )
    end
  end

  context 'when there are no grantees at all (degenerate guard)' do
    it 'skips entirely rather than creating an unusable connect role' do
      expect(chef_run).not_to run_postgresql_query('restrict database access for no_grantees_db')
      expect(chef_run).not_to create_postgresql_role('no_grantees_db_connect')
    end
  end

  context 'when the node is a replica' do
    before do
      allow_any_instance_of(PgHelper).to receive(:replica?).and_return(true)
    end

    it 'does not enforce anything (writes replicate via WAL)' do
      expect(chef_run.find_resources(:postgresql_query)).to be_empty
      expect(chef_run).not_to create_postgresql_role('gitlabhq_production_connect')
    end
  end
end
