resource_name :postgresql_query
provides :postgresql_query

unified_mode true

property :description, String, name_property: true
property :query, String
property :db_name, String, default: 'template1'
property :helper, default: lazy { PgHelper.new(node) }

action :run do
  account_helper = AccountHelper.new(node)

  execute "#{new_resource.description} (#{new_resource.helper.service_name})" do
    command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d #{new_resource.db_name} -c "#{new_resource.query}")
    user account_helper.postgresql_user
    only_if { new_resource.helper.is_ready? }
    not_if { new_resource.helper.is_offline_or_readonly? }
  end
end
