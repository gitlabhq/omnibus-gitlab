resource_name :postgresql_query

property :description, String, name_property: true
property :query, String
property :db_name, String, default: 'template1'
property :helper, default: PgHelper.new(node)

action :run do
  account_helper = AccountHelper.new(node)

  execute "#{description} (#{helper.service_cmd})" do
    command %(/opt/gitlab/bin/#{helper.service_cmd} -d #{db_name} -c "#{query}")
    user account_helper.postgresql_user
    retries 20
    not_if { helper.is_offline_or_readonly? }
  end
end
