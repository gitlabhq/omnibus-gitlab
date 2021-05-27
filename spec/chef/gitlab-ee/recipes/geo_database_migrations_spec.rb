require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the bash block.
#

RSpec.describe 'gitlab-ee::geo-database-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when migration should run' do
    before do
      stub_default_not_listening?(false)
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
        puma
        gitaly
        geo-postgresql
        gitlab-pages
        geo-logcursor
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    it 'runs the migrations with expected attributes' do
      expect(chef_run).to run_rails_migration('gitlab-geo tracking') do |resource|
        expect(resource.dependent_services).to include_array(%w(runit_service[puma] sidekiq_service[sidekiq]))
        expect(resource.rake_task).to eq('geo:db:migrate')
        expect(resource.logfile_prefix).to eq('gitlab-geo-db-migrate')
        expect(resource.helper).to be_a(GitlabGeoHelper)
      end
    end

    it 'starts geo-postgresql if its not running' do
      stub_not_listening?('geo-postgresql', true)

      expect(chef_run.rails_migration('gitlab-geo tracking')).to notify('execute[start geo-postgresql]').to(:run)
    end
  end

  context 'with auto_migrate off' do
    it 'skips running the migrations' do
      stub_gitlab_rb({
                       geo_secondary_role: { enable: true },
                       geo_secondary: { auto_migrate: false }
                     })

      expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
      expect(chef_run).not_to run_rails_migration('gitlab-geo tracking')
    end
  end
end
