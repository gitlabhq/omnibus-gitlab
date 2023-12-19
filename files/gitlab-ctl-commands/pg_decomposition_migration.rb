require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql/decomposition_migration"

add_command_under_category('pg-decomposition-migration', 'database', 'Migrate database to two-database setup', 2) do |_cmd, user|
  PostgreSQL::DecompositionMigration.new(self).migrate!
end
