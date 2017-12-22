resource_name :postgresql_fdw_user_mapping

property :server_name, String, name_property: true
property :db_user, String
property :db_name, String
property :external_user, String
property :external_password, String
property :helper, default: PgHelper.new(node)

action :create do
  postgresql_query "create mapping for #{db_user} at #{server_name}" do
    query "CREATE USER MAPPING FOR #{db_user} SERVER #{server_name} OPTIONS (user '#{external_user}', password '#{external_password}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      helper.is_offline_or_readonly? ||
        !helper.fdw_server_exists?(server_name, db_name) ||
        helper.fdw_user_mapping_exists?(db_user, server_name, db_name)
    end
  end

  postgresql_query "update mapping for #{db_user} at #{server_name}" do
    query "ALTER USER MAPPING FOR #{db_user} SERVER #{server_name} OPTIONS (SET user '#{external_user}', SET password '#{external_password}');"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      helper.is_offline_or_readonly? ||
        !helper.fdw_server_exists?(server_name, db_name) ||
        !helper.fdw_user_mapping_exists?(db_user, server_name, db_name) ||
        !helper.fdw_user_mapping_changed?(db_user, server_name, db_name, user: external_user, password: external_password)
    end
  end

  postgresql_query "grant usage on foreign server #{server_name} to #{db_user}" do
    query "GRANT USAGE ON FOREIGN SERVER #{server_name} TO #{db_user};"
    db_name new_resource.db_name
    helper new_resource.helper

    not_if do
      helper.is_offline_or_readonly? ||
        !helper.fdw_server_exists?(server_name, db_name) ||
        helper.fdw_user_has_server_privilege?(db_user, server_name, db_name, 'USAGE')
    end
  end
end
