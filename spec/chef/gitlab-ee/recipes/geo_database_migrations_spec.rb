require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the bash block.
#

RSpec.describe 'gitlab-ee::geo-database-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
  let(:name) { 'migrate gitlab-geo tracking database' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when migration should run' do
    before do
      allow_any_instance_of(OmnibusHelper).to receive(:not_listening?).and_return(false)
      stub_gitlab_rb(geo_secondary_role: { enable: true })

      # Make sure other calls to `File.symlink?` are allowed.
      allow(File).to receive(:symlink?).and_call_original
      %w(
        alertmanager
        gitlab-exporter
        gitlab-workhorse
        logrotate
        nginx
        node-exporter
        postgres-exporter
        postgresql
        prometheus
        redis
        redis-exporter
        sidekiq
        sidekiq-cluster
        unicorn
        puma
        actioncable
        gitaly
        geo-postgresql
        gitlab-pages
        geo-logcursor
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    let(:bash_block) { chef_run.bash(name) }

    it 'runs the migrations' do
      expect(chef_run).to run_bash(name)
    end

    # The reverse can't be tested in a unit test due to
    # https://github.com/chefspec/chefspec/issues/546
    context 'when database has not been migrated' do
      it 'restarts services' do
        allow_any_instance_of(GitlabGeoHelper).to receive(:migrated?).and_return(false)

        expect(bash_block).to notify('runit_service[puma]').to(:restart)
        expect(bash_block).to notify('sidekiq_service[sidekiq]').to(:restart)
      end
    end

    context 'places the log file' do
      it 'in a default location' do
        path = Regexp.escape('/var/log/gitlab/gitlab-rails/gitlab-geo-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log')
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
        expect(bash_block.code).to match(/#{path}/)
      end

      it 'in a custom location' do
        path = '/tmp/gitlab-geo-db-migrate-'
        stub_gitlab_rb(gitlab_rails: { log_directory: '/tmp' })
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
        expect(bash_block.code).to match(/#{path}/)
      end
    end

    context 'with auto_migrate off' do
      before do
        stub_gitlab_rb(geo_secondary: { auto_migrate: false })
      end

      it 'skips running the migrations' do
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
        expect(chef_run).not_to run_bash(name)
      end
    end
  end
end
