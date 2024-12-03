pgbouncer_user 'example' do
  database 'database'
  user 'database_user'
  password 'password123'
  add_auth_function true
  helper PgHelper.new(node)
end
