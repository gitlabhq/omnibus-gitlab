resource_name :postgresql_fdw_user_mapping

property :server_name, String, name_property: true
property :db_user, String
property :db_name, String
property :external_user, String
property :external_password, String
property :helper, default: PgHelper.new(node)

action :create do
  postgresql_query "create mapping for #{new_resource.db_user} at #{new_resource.server_name}" do
    query "CREATE USER MAPPING FOR #{new_resource.db_user} SERVER #{new_resource.server_name} OPTIONS (user '#{new_resource.external_user}', password '#{new_resource.external_password}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) ||
        new_resource.helper.fdw_user_mapping_exists?(new_resource.db_user, new_resource.server_name, new_resource.db_name)
    end
  end

  postgresql_query "update mapping for #{new_resource.db_user} at #{new_resource.server_name}" do
    query "ALTER USER MAPPING FOR #{new_resource.db_user} SERVER #{new_resource.server_name} OPTIONS (#{new_resource.helper.fdw_user_mapping_update_options(new_resource)});"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) ||
        !new_resource.helper.fdw_user_mapping_exists?(new_resource.db_user, new_resource.server_name, new_resource.db_name) ||
        !new_resource.helper.fdw_user_mapping_changed?(new_resource.db_user, new_resource.server_name, new_resource.db_name, user: new_resource.external_user, password: new_resource.external_password)
    end
  end

  postgresql_query "grant usage on foreign server #{new_resource.server_name} to #{new_resource.db_user}" do
    query "GRANT USAGE ON FOREIGN SERVER #{new_resource.server_name} TO #{new_resource.db_user};"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.fdw_server_exists?(new_resource.server_name, new_resource.db_name) ||
        new_resource.helper.fdw_user_has_server_privilege?(new_resource.db_user, new_resource.server_name, new_resource.db_name, 'USAGE')
    end
  end
end
