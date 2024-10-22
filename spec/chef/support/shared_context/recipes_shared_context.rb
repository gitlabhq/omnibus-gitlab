require 'chef_helper'

RSpec.shared_context 'recipes' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  let(:mandatory_recipes) do
    recipes =
      [
        "gitlab-ee::default",
        "pgbouncer::user",
        "gitlab::default",
        "gitlab::config",
        "postgresql::directory_locations",
        "gitlab::web-server",
        "gitlab::users",
        "gitlab::selinux",
        "gitlab::add_trusted_certs",
        "package::runit",
        "package::sysctl",
        "logrotate::enable",
        "logrotate::folders_and_configs",
        "postgresql::bin",
        "gitlab::bootstrap",
        "monitoring::default",
        "monitoring::node-exporter",
        "monitoring::user"
      ]
    runit_recipe = if File.directory?('/run/systemd/system')
                     ["package::runit_systemd"]
                   else
                     []
                   end
    recipes + runit_recipe
  end

  let(:default_service_enable_recipes) do
    ["gitlab::gitlab-rails",
     "gitaly::git_data_dirs",
     "gitlab::rails_pages_shared_path",
     "gitlab::gitlab-shell",
     "redis::enable",
     "gitaly::enable",
     "postgresql::enable",
     "postgresql::user",
     "postgresql::sysctl",
     "postgresql::standalone",
     "gitlab-kas::enable",
     "gitlab::database_migrations",
     "gitlab::puma",
     "gitlab::sidekiq",
     "gitlab::gitlab-workhorse",
     "gitlab::nginx",
     "nginx::enable",
     "gitlab::gitlab-healthcheck",
     "monitoring::gitlab-exporter",
     "monitoring::redis-exporter",
     "monitoring::prometheus",
     "monitoring::alertmanager",
     "monitoring::postgres-exporter",
     "gitlab-ee::suggested_reviewers"]
  end

  let(:default_service_disable_recipes) do
    [
      "redis::disable",
      "gitaly::disable",
      "postgresql::disable",
      "gitlab-kas::disable",
      "gitlab::puma_disable",
      "gitlab::sidekiq_disable",
      "gitlab::gitlab-workhorse_disable",
      "gitlab::nginx_disable",
      "monitoring::gitlab-exporter_disable",
      "monitoring::redis-exporter_disable",
      "monitoring::prometheus_disable",
      "monitoring::alertmanager_disable",
      "monitoring::postgres-exporter_disable",
    ]
  end

  let(:extra_disable_recipes) do
    [
      "spamcheck::disable",
      "praefect::disable",
      "crond::disable",
      "gitlab::mailroom_disable",
      "gitlab::remote-syslog_disable",
      "gitlab::storage-check_disable",
      "gitlab-pages::disable",
      "registry::disable",
      "mattermost::disable",
      "letsencrypt::disable",
      "monitoring::pgbouncer-exporter_disable",
      "gitlab::gitlab-backup-cli_disable",
      "gitlab::database_reindexing_disable",
      "gitlab-ee::sentinel_disable",
      "gitlab-ee::geo-postgresql_disable",
      "gitlab-ee::geo-logcursor_disable",
      "consul::disable",
      "consul::disable_daemon",
      "pgbouncer::disable",
      "patroni::disable",
      "gitlab-ee::geo-secondary_disable",
    ]
  end

  shared_examples 'enable only default service recipes' do
    it 'only default service recipes are run' do
      expected_recipes = mandatory_recipes + default_service_enable_recipes + extra_disable_recipes
      expect(chef_run.run_context.loaded_recipes).to match_array(expected_recipes)
    end
  end

  shared_examples 'enable recipes required for the service only' do |roles, include_recipes, exclude_recipes|
    before do
      stub_gitlab_rb(
        roles: roles
      )
    end

    it 'only recipes required for the service are run' do
      expected_recipes = mandatory_recipes + default_service_disable_recipes + extra_disable_recipes + include_recipes - exclude_recipes
      expect(chef_run.run_context.loaded_recipes).to match_array(expected_recipes)
    end
  end
end
