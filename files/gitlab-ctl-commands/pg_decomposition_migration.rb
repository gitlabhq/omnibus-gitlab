require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/postgresql/decomposition_migration"

add_command_under_category('pg-decomposition-migration', 'database', 'Migrate database to two-database setup', 2) do |_cmd, user|
  GitlabCtl::PostgreSQL::DecompositionMigration.new(self).migrate!
end
