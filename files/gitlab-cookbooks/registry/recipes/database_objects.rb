# registry/recipes/database_objects.rb

pg_helper = PgHelper.new(node)

registry_database_objects 'default' do
  pg_helper pg_helper
  action :create
  only_if { node.dig('postgresql', 'enable') }
  not_if { pg_helper.replica? }
  # TODO: notifies :create, 'registry_database_migrations[up]', :immediately if pg_helper.is_ready?
end
