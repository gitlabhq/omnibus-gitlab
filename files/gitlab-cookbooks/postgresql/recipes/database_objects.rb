# Create database objects, including roles, extensions, and functions.
# This recipe is used by `postgresql::enable` and `patroni::enable` recipes.

pg_helper = PgHelper.new(node)

# The following resources can not be created/modified on read-only secondary nodes.
return if pg_helper.is_slave?

postgresql_username = AccountHelper.new(node).postgresql_user

pg_port = node['postgresql']['port']
database_name = node['gitlab']['gitlab-rails']['db_database']
gitlab_sql_user = node['postgresql']['sql_user']
gitlab_sql_user_password = node['postgresql']['sql_user_password']
sql_replication_user = node['postgresql']['sql_replication_user']
sql_replication_password = node['postgresql']['sql_replication_password']
pgbouncer_sql_user = node['postgresql']['pgbouncer_user']
pgbouncer_sql_user_password = node['postgresql']['pgbouncer_user_password'] || ''
auth_query = node['gitlab']['pgbouncer']['auth_query']
default_auth_query = node.default['gitlab']['pgbouncer']['auth_query']

rails_enabled = node['gitlab']['gitlab-rails']['enable']
patroni_enabled = node['patroni']['enable']

if patroni_enabled || rails_enabled
  postgresql_user gitlab_sql_user do
    password "md5#{gitlab_sql_user_password}" unless gitlab_sql_user_password.nil?
    action :create
  end

  postgresql_user sql_replication_user do
    password "md5#{sql_replication_password}" unless sql_replication_password.nil?
    options %w(replication)
    action :create
  end

  execute "create #{database_name} database" do
    command "/opt/gitlab/embedded/bin/createdb --port #{pg_port} -h #{node['postgresql']['unix_socket_directory']} -O #{gitlab_sql_user} #{database_name}"
    user postgresql_username
    retries 30
    not_if { !pg_helper.is_running? || pg_helper.database_exists?(database_name) }
  end
end

if patroni_enabled
  pgbouncer_user 'patroni' do
    user pgbouncer_sql_user
    password pgbouncer_sql_user_password
    database database_name
    add_auth_function default_auth_query.eql?(auth_query)
    pg_helper pg_helper
    action :create
  end
end

postgresql_extension 'pg_trgm' do
  database database_name
  action :enable
end

postgresql_extension 'btree_gist' do
  database database_name
  action :enable
end
