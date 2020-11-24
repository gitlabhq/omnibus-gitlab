resource_name :database_objects
provides :database_objects

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

  execute "create #{database_name} database" do
    command "/opt/gitlab/embedded/bin/createdb --port #{pg_port} -h #{pg_host} -O #{gitlab_sql_user} #{database_name}"
    user postgresql_username
    retries 30
    only_if { rails_enabled && new_resource.pg_helper.is_running? && !new_resource.pg_helper.database_exists?(database_name) }
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
