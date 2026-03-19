# Test fixture recipe for registry_database_objects resource
pg_helper = PgHelper.new(node)

registry_database_objects 'default' do
  pg_helper pg_helper
  action :create
end
