resource_name :postgresql_user

property :username, String, name_property: true
property :password, String

action :create do
  account_helper = AccountHelper.new(node)
  pg_helper = PgHelper.new(node)

  query = if password.nil?
            "CREATE USER #{username};"
          else
            "CREATE USER #{username} PASSWORD '#{password}';"
          end
  execute "create #{username} postgresql user" do
    command %(/opt/gitlab/bin/gitlab-psql -d template1 -c "#{query}")
    user account_helper.postgresql_user
    # Added retries to give the service time to start on slower systems
    retries 20
    not_if { !pg_helper.is_running? || pg_helper.user_exists?(username) }
  end
end
