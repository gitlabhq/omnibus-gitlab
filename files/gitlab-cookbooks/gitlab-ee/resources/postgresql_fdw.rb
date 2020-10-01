resource_name :postgresql_fdw
provides :postgresql_fdw

property :server_name, String, name_property: true
property :db_name, String
property :external_host, String
property :external_port, Integer
property :external_name, String
property :helper, default: PgHelper.new(node)

action :delete do
  postgresql_query "drop fdw #{new_resource.server_name} on #{new_resource.db_name}" do
    query "DROP SERVER #{new_resource.server_name} CASCADE;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if { new_resource.helper.is_offline_or_readonly? || !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) }
  end

  postgresql_query "drop postgres_fdw extension on #{new_resource.db_name}" do
    query "DROP EXTENSION IF EXISTS postgres_fdw;"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.extension_enabled?('postgres_fdw', new_resource.db_name)
    end
  end
end
