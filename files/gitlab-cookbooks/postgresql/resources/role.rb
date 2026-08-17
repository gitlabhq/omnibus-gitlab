# postgresql/resources/role.rb
#
# Creates a NOLOGIN PostgreSQL role used as a permission container (the "roles
# are permissions, users are identities" model). Unlike `postgresql_user`, which
# always emits `CREATE USER` (LOGIN), this creates a `CREATE ROLE ... NOLOGIN`
# and does not manage a password.

unified_mode true

# The rolename is interpolated into a quoted SQL identifier, so reject the one
# character that could break out of those quotes. Current callers only ever
# produce "<database>_connect", but this makes the safety explicit.
property :rolename, String, name_property: true,
                            callbacks: { 'must not contain a double quote' => ->(v) { !v.include?('"') } }
property :helper, [PgHelper, GeoPgHelper], default: lazy { PgHelper.new(node) }, sensitive: true

action :create do
  account_helper = AccountHelper.new(node)

  query = %(CREATE ROLE \\"#{new_resource.rolename}\\" NOLOGIN)

  execute "create #{new_resource.rolename} postgresql role" do
    command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d template1 -c "#{query}")
    user account_helper.postgresql_user
    only_if { new_resource.helper.is_running? && new_resource.helper.is_ready? }
    not_if { new_resource.helper.is_offline_or_readonly? || new_resource.helper.role_exists?(new_resource.rolename) }
  end
end
