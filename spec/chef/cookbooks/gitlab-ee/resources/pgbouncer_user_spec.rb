require 'chef_helper'
RSpec.describe 'pgbouncer_user' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: ['pgbouncer_user']) }

  context 'create geo' do
    let(:chef_run) { runner.converge('test_gitlab_ee::pgbouncer_user_create_geo') }
    it 'should create the pgbouncer user' do
      expect(chef_run).to create_postgresql_user('pgbouncer-geo').with(
        helper: an_instance_of(GeoPgHelper),
        username: 'pgbouncer-geo',
        password: 'md5fakepassword-geo'
      )
    end

    it 'should create the pg_shadow_lookup function' do
      postgresql_user = chef_run.postgresql_user('pgbouncer-geo')
      expect(postgresql_user.username).to eq('pgbouncer-geo')
      resource = chef_run.execute('Add pgbouncer auth function')
      expect(resource.command).to match(%r{^/opt/gitlab/bin/gitlab-geo-psql -d fakedb-geo})
    end
  end

  context 'create rails' do
    let(:chef_run) { runner.converge('test_gitlab_ee::pgbouncer_user_create_rails') }
    it 'should create the pgbouncer user' do
      expect(chef_run).to create_postgresql_user('pgbouncer-rails').with(
        helper: an_instance_of(PgHelper),
        username: 'pgbouncer-rails',
        password: 'md5fakepassword-rails'
      )
    end

    it 'should create the pg_shadow_lookup function' do
      postgresql_user = chef_run.postgresql_user('pgbouncer-rails')
      expect(postgresql_user.username).to eq('pgbouncer-rails')
      resource = chef_run.execute('Add pgbouncer auth function')
      expect(resource.command).to match(%r{^/opt/gitlab/bin/gitlab-psql -d fakedb-rails})
    end
  end
end
