pgbouncer_user 'rails' do
  helper PgHelper.new(node)
  user 'pgbouncer-rails'
  password 'fakepassword-rails'
  database 'fakedb-rails'
  add_auth_function true
  action :create
end
