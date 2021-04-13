property :database, String, name_property: true
property :owner, String, default: lazy { node['postgresql']['sql_user'] }
property :helper, default: lazy { PgHelper.new(node) }
property :database_port, Integer, default: lazy { node['postgresql']['port'] }
property :database_socket, String, default: lazy { node['postgresql']['unix_socket_directory'] }

action :create do
  account_helper = AccountHelper.new(node)

  execute "create database #{new_resource.database}" do
    command %(/opt/gitlab/embedded/bin/createdb --port #{new_resource.database_port} -h #{new_resource.database_socket} -O #{new_resource.owner} #{new_resource.database})
    user account_helper.postgresql_user
    retries 30
    not_if { !new_resource.helper.is_running? || new_resource.helper.database_exists?(new_resource.database) }
  end
end
