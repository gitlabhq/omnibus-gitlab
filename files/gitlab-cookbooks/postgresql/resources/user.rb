unified_mode true

property :username, String, name_property: true
property :password, String
property :options, Array
property :helper, default: lazy { PgHelper.new(node) }

action :create do
  account_helper = AccountHelper.new(node)

  query = %(CREATE USER \\"#{new_resource.username}\\")

  execute "create #{new_resource.username} postgresql user" do
    command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d template1 -c "#{query}")
    user account_helper.postgresql_user
    only_if { new_resource.helper.is_running? && new_resource.helper.is_ready? }
    not_if { new_resource.helper.is_offline_or_readonly? || new_resource.helper.user_exists?(new_resource.username) }
  end

  if property_is_set?(:password)
    query = %(ALTER USER \\"#{new_resource.username}\\")
    query << if new_resource.password.nil?
               %( WITH PASSWORD NULL )
             else
               %( WITH PASSWORD '#{new_resource.password}')
             end

    execute "set password for #{new_resource.username} postgresql user" do
      command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d template1 -c "#{query}")
      user account_helper.postgresql_user
      only_if { new_resource.helper.is_running? && new_resource.helper.is_ready? }
      not_if { new_resource.helper.is_offline_or_readonly? || !new_resource.helper.user_exists?(new_resource.username) || new_resource.helper.user_password_match?(new_resource.username, new_resource.password) }
    end
  end

  if property_is_set?(:options)
    query = %(ALTER USER \\"#{new_resource.username}\\" #{new_resource.options.join(' ')})

    execute "set options for #{new_resource.username} postgresql user" do
      command %(/opt/gitlab/bin/#{new_resource.helper.service_cmd} -d template1 -c "#{query}")
      user account_helper.postgresql_user
      only_if { new_resource.helper.is_running? && new_resource.helper.is_ready? }
      not_if { new_resource.helper.is_offline_or_readonly? || !new_resource.helper.user_exists?(new_resource.username) || new_resource.helper.user_options_set?(new_resource.username, new_resource.options) }
    end
  end
end
