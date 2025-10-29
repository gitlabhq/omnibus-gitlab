# CAUTION: This recipe is only to be used by the PostgreSQL node
# because it's the only node which has access to the `postgresql`
# user with permission to create database objects.
pg_helper = PgHelper.new(node)

registry_database_objects 'default' do
  pg_helper pg_helper
  action :create
  only_if { node.dig('postgresql', 'enable') }
  not_if { pg_helper.replica? }
end
