property :username, String, name_property: true
property :password, String
property :options, Array
property :helper, default: PgHelper.new(node)

action :create do
  account_helper = AccountHelper.new(node)

  query = %(CREATE USER \\"#{username}\\")

  execute "create #{username} postgresql user" do
    command %(/opt/gitlab/bin/#{helper.service_cmd} -d template1 -c "#{query}")
    user account_helper.postgresql_user
    # Added retries to give the service time to start on slower systems
    retries 20
    not_if { !helper.is_running? || helper.user_exists?(username) }
  end

  if property_is_set?(:password)
    query = %(ALTER USER \\"#{username}\\")
    query << if password.nil?
               %( WITH PASSWORD NULL )
             else
               %( WITH PASSWORD '#{password}')
             end

    execute "set password for #{username} postgresql user" do
      command %(/opt/gitlab/bin/#{helper.service_cmd} -d template1 -c "#{query}")
      user account_helper.postgresql_user
      # Added retries to give the service time to start on slower systems
      retries 20
      not_if { !helper.is_running? || !helper.user_exists?(username) || helper.user_password_match?(username, password) }
    end
  end

  if property_is_set?(:options)
    query = %(ALTER USER \\"#{username}\\" #{options.join(' ')})

    execute "set options for #{username} postgresql user" do
      command %(/opt/gitlab/bin/#{helper.service_cmd} -d template1 -c "#{query}")
      user account_helper.postgresql_user
      # Added retries to give the service time to start on slower systems
      retries 20
      not_if { !helper.is_running? || !helper.user_exists?(username) || helper.user_options_set?(username, options) }
    end
  end
end
