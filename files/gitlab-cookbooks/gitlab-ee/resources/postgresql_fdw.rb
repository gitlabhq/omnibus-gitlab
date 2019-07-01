resource_name :postgresql_fdw

property :server_name, String, name_property: true
property :db_name, String
property :external_host, String
property :external_port, Integer
property :external_name, String
property :helper, default: PgHelper.new(node)

action :create do
  postgresql_query "enable postgres_fdw extension on #{new_resource.db_name}" do
    query "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        new_resource.helper.extension_enabled?('postgres_fdw', new_resource.db_name)
    end
  end

  postgresql_query "create fdw #{new_resource.server_name} on #{new_resource.db_name}" do
    query "CREATE SERVER #{new_resource.server_name} FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '#{new_resource.external_host}', port '#{new_resource.external_port}', dbname '#{new_resource.external_name}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name)
    end
  end

  postgresql_query "update fdw #{new_resource.server_name} on #{new_resource.db_name}" do
    query "ALTER SERVER #{new_resource.server_name} OPTIONS (SET host '#{new_resource.external_host}', SET port '#{new_resource.external_port}', SET dbname '#{new_resource.external_name}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) ||
        !new_resource.helper.fdw_server_options_changed?(new_resource.server_name, new_resource.db_name, host: new_resource.external_host, port: new_resource.external_port, dbname: new_resource.external_name)
    end
  end
end

action :delete do
  postgresql_query "drop fdw #{new_resource.server_name} on #{new_resource.db_name}" do
    query "DROP SERVER #{new_resource.server_name} CASCADE;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if { new_resource.helper.is_offline_or_readonly? || !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) }
  end
end
