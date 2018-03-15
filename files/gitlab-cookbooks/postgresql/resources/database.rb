property :database, String, name_property: true
property :owner, String, default: lazy { node['gitlab']['postgresql']['sql_user'] }
property :helper, default: lazy { PgHelper.new(node) }
property :database_port, Integer, default: lazy { node['gitlab']['postgresql']['port'] }
property :database_socket, String, default: lazy { node['gitlab']['postgresql']['unix_socket_directory'] }

action :create do
  account_helper = AccountHelper.new(node)

  execute "create database #{database}" do
    command %(/opt/gitlab/embedded/bin/createdb --port #{database_port} -h #{database_socket} -O #{owner} #{database})
    user account_helper.postgresql_user
    retries 30
    not_if { !helper.is_running? || helper.database_exists?(database) }
  end
end
