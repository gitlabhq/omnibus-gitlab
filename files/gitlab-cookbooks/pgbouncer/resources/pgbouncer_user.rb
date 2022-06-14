resource_name :pgbouncer_user
provides :pgbouncer_user

unified_mode true

property :type, String, name_property: true
property :account_helper, default: AccountHelper.new(node)
property :add_auth_function, [true, false], required: true
property :database, String, required: true
property :password, String, required: true
property :helper, [GeoPgHelper, PgHelper], required: true
property :user, String, required: true

action :create do
  postgresql_user new_resource.user do
    helper new_resource.helper
    password "md5#{new_resource.password}"
    action :create
    notifies :run, "execute[Add pgbouncer auth function]", :immediately
  end

  pgbouncer_auth_function = new_resource.helper.pg_shadow_lookup

  execute 'Add pgbouncer auth function' do
    command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d #{new_resource.database} -c '#{pgbouncer_auth_function}')
    user new_resource.account_helper.postgresql_user
    not_if { new_resource.helper.has_function?(new_resource.database, "pg_shadow_lookup") }
    only_if { new_resource.add_auth_function }
    action :nothing
  end
end
