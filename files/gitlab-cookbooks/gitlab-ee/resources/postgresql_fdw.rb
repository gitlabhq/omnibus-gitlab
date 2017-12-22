resource_name :postgresql_fdw

property :server_name, String, name_property: true
property :db_name, String
property :external_host, String
property :external_port, Integer
property :external_name, String
property :helper, default: PgHelper.new(node)

action :create do
  postgresql_query "enable postgres_fdw extension on #{db_name}" do
    query "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if { helper.is_offline_or_readonly? || helper.extension_enabled?('postgres_fdw', db_name) }
  end

  postgresql_query "create fdw #{server_name} on #{db_name}" do
    query "CREATE SERVER #{server_name} FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '#{external_host}', port '#{external_port}', dbname '#{external_name}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if { helper.is_offline_or_readonly? || helper.fdw_server_exists?(server_name, db_name) }
  end

  postgresql_query "up fdw #{server_name} on #{db_name}" do
    query "ALTER SERVER #{server_name} OPTIONS (SET host '#{external_host}', SET port '#{external_port}', SET dbname '#{external_name}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      helper.is_offline_or_readonly? ||
        !helper.fdw_server_exists?(server_name, db_name) ||
        !helper.fdw_server_options_changed?(server_name, db_name, host: external_host, port: external_port, dbname: external_name)
    end
  end
end

action :delete do
  postgresql_query "drop fdw #{server_name} on #{db_name}" do
    query "DROP SERVER #{server_name} CASCADE;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if { helper.is_offline_or_readonly? || !helper.fdw_server_exists?(server_name, db_name) }
  end
end
