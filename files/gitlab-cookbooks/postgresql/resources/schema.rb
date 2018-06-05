property :schema, String, name_property: true
property :database, String
property :owner, String, default: 'CURRENT_USER'
property :helper, default: lazy { PgHelper.new(node) }

action :create do
  postgresql_query "create #{new_resource.schema} schema on #{new_resource.database}" do
    query "CREATE SCHEMA #{new_resource.schema} AUTHORIZATION #{new_resource.owner};"
    db_name new_resource.database
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        new_resource.helper.schema_exists?(new_resource.schema, new_resource.database)
    end
  end

  postgresql_query "modify #{new_resource.schema} schema owner on #{new_resource.database}" do
    query %(ALTER SCHEMA #{new_resource.schema} OWNER TO "#{new_resource.owner}")
    db_name new_resource.database
    helper new_resource.helper

    not_if do
      new_resource.helper.is_offline_or_readonly? ||
        !new_resource.helper.schema_exists?(new_resource.schema, new_resource.database) ||
        new_resource.helper.schema_owner?(new_resource.schema, new_resource.database, new_resource.owner)
    end
  end
end
