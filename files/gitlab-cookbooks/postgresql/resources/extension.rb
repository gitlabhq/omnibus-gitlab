unified_mode true

property :extension, String, name_property: true
property :database, String
property :helper, default: lazy { PgHelper.new(node) }

action :enable do
  postgresql_query "enable #{new_resource.extension} extension" do
    query %(CREATE EXTENSION IF NOT EXISTS #{new_resource.extension})
    db_name new_resource.database
    helper new_resource.helper
    action :run
    only_if { new_resource.helper.extension_can_be_enabled?(new_resource.extension, new_resource.database) }
  end
end
