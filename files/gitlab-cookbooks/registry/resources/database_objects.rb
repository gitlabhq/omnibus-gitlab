# registry/resources/database_objects.rb

unified_mode true

property :pg_helper, [GeoPgHelper, PgHelper], required: true, sensitive: true

default_action :nothing

action :nothing do
end

action :create do
  host = node['postgresql']['unix_socket_directory']
  port = node['postgresql']['port']
  database_name = node['postgresql']['registry']['dbname']
  username = node['postgresql']['registry']['user']
  password = node['postgresql']['registry']['password']
  postgresql_user username do
    password "md5#{password}" unless password.nil?

    action :create
  end

  postgresql_database database_name do
    database_socket host
    database_port port
    owner username
    helper new_resource.pg_helper

    action :create
  end
end
