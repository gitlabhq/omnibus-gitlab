require 'io/console'

class PostgreSQL
  class DecompositionMigration
    def initialize(ctl)
      @ctl = ctl
    end

    def migrate!
      unless @ctl.service_enabled?('postgresql')
        puts 'There is no PostgreSQL instance enabled in Omnibus, exiting...'
        exit 1
      end

      puts <<~MSG
      This script will migrate this GitLab instance to a two-database setup.

      WARNING:
      - This script is experimental. See https://docs.gitlab.com/ee/administration/postgresql/multiple_databases.html
      - Once migrated to a two-database setup, you cannot migrate it back.

      Ensure:
      - The new database 'gitlabhq_production_ci' has been created, for example:

      gitlab-psql -c "CREATE DATABASE gitlabhq_production_ci WITH OWNER 'gitlab'"

      - The following changes are added to /etc/gitlab/gitlab.rb configuration file
        but do **not** run 'gitlab-ctl reconfigure' yet:

      gitlab_rails['env'] = { 'GITLAB_ALLOW_SEPARATE_CI_DATABASE' => 'true' }
      gitlab_rails['databases']['ci']['enable'] = true
      gitlab_rails['databases']['ci']['db_database'] = 'gitlabhq_production_ci'

      This script will:
      - Disable background migrations because they should not be active during this migration
        See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#enable-or-disable-background-migrations
      - Stop the Gitlab Instance
      - Copy data in gitlabhq_production to gitlabhq_production_ci (by dumping, then restoring)
      - Apply configuration changes in /etc/gitlab/gitlab.rb using 'gitlab-ctl reconfigure'
      - Prevent errorneous database access
      - Re-enable background migrations
      - Restart GitLab

      This script will not:
      - Clean up data in the databases

      Please confirm the upgrade by pressing 'y':
      MSG

      prompt = $stdin.gets.chomp

      exit(1) unless prompt.casecmp('y').zero?

      disable_background_migrations unless background_migrations_initally_disabled?
      stop_gitlab_services
      run_migration
      post_migrate

      puts <<~MSG
      GitLab is now running on two databases. Data related to CI is now written to the ci
      database.

      You can also remove duplicated data by running:
      'sudo gitlab-rake gitlab:db:truncate_legacy_tables:main'
      'sudo gitlab-rake gitlab:db:truncate_legacy_tables:ci'

      MSG
    end

    private

    def background_migrations_initally_disabled?
      @background_migrations_initally_disabled ||= GitlabCtl::Util.run_command(
        'gitlab-rails runner "puts (Feature.disabled?(:execute_background_migrations, type: :ops) && Feature.disabled?(:execute_batched_migrations_on_schedule, type: :ops)).to_s"'
      ).stdout.chomp == "true"
    end

    def disable_background_migrations
      puts "Disabling Background Migrations..."
      run_command <<~CMD
      gitlab-rails runner "Feature.disable(:execute_background_migrations) && Feature.disable(:execute_batched_migrations_on_schedule)"
      CMD
    end

    def enable_background_migrations
      puts "Enabling Background Migrations..."
      run_command <<~CMD
      gitlab-rails runner "Feature.enable(:execute_background_migrations) && Feature.enable(:execute_batched_migrations_on_schedule)"
      CMD
    end

    def stop_gitlab_services
      puts "Stopping GitLab..."
      run_command("gitlab-ctl stop && gitlab-ctl start postgresql")
    end

    def run_migration
      puts "Copying data to new database..."
      run_command("gitlab-rake gitlab:db:decomposition:migrate")
    end

    def post_migrate
      puts "Reconfigure GitLab..."
      run_command("gitlab-ctl reconfigure")
      puts "Enable write locks..."
      run_command("gitlab-rake gitlab:db:lock_writes")
      enable_background_migrations unless background_migrations_initally_disabled?
      puts "Restarting GitLab..."
      run_command("gitlab-ctl restart")
    end

    def run_command(cmd)
      GitlabCtl::Util.run_command(cmd).tap do |status|
        if status.error?
          enable_background_migrations unless background_migrations_initally_disabled?

          puts status.stdout
          puts status.stderr
          puts "[ERROR] Failed to execute: #{cmd}"
          puts "This GitLab instance is still disabled."

          exit 1
        end
      end
    end
  end
end
