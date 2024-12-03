require 'chef_helper'

RSpec.describe 'pgbouncer_user' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(pgbouncer_user)) }

  context 'create' do
    let(:chef_run) { runner.converge('test_pgbouncer::pgbouncer_user_create') }

    it 'ensures the auth function is owned by the correct user' do
      allow_any_instance_of(AccountHelper).to receive(:postgresql_user).and_return('superuser')
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:is_ready?).and_return(true)
      expect(chef_run).to run_execute('Ensure ownership of auth function').with(
        command: %(/opt/gitlab/bin/gitlab-psql -d database -c 'ALTER FUNCTION pg_shadow_lookup OWNER TO \"superuser\"'),
        user: 'superuser'
      )
    end
  end
end
