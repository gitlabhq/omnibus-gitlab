postgresql_database_access 'gitlabhq_production' do
  connect_users %w(gitlab)
  pgbouncer_user 'pgbouncer'
  pg_helper PgHelper.new(node)
end

postgresql_database_access 'no_pgbouncer_db' do
  connect_users %w(appuser)
  pg_helper PgHelper.new(node)
end

postgresql_database_access 'custom_schema_db' do
  connect_users %w(appuser)
  schemas %w(public partitions)
  pg_helper PgHelper.new(node)
end

postgresql_database_access 'no_grantees_db' do
  connect_users []
  pg_helper PgHelper.new(node)
end
