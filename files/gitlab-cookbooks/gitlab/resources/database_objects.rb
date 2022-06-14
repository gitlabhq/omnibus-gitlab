resource_name :database_objects
provides :database_objects

unified_mode true

property :pg_helper, [GeoPgHelper, PgHelper], required: true
property :account_helper, [AccountHelper], required: true

action :create do
  rails_enabled = node['gitlab']['gitlab-rails']['enable']

  postgresql_username = new_resource.account_helper.postgresql_user
  pg_host = node['postgresql']['unix_socket_directory']
  pg_port = node['postgresql']['port']
  database_name = node['gitlab']['gitlab-rails']['db_database']
  gitlab_sql_user = node['postgresql']['sql_user']
  gitlab_sql_user_password = node['postgresql']['sql_user_password']
  sql_replication_user = node['postgresql']['sql_replication_user']
  sql_replication_password = node['postgresql']['sql_replication_password']

  postgresql_user gitlab_sql_user do
    password "md5#{gitlab_sql_user_password}" unless gitlab_sql_user_password.nil?
    action :create
  end

  postgresql_user sql_replication_user do
    password "md5#{sql_replication_password}" unless sql_replication_password.nil?
    options %w(replication)
    action :create
  end

  postgresql_database database_name do
    database_port pg_port
    database_socket pg_host
    owner gitlab_sql_user
    user postgresql_username
    helper new_resource.pg_helper

    only_if { rails_enabled }
  end

  postgresql_extension 'pg_trgm' do
    database database_name
    action :enable
  end

  postgresql_extension 'btree_gist' do
    database database_name
    action :enable
  end
end
