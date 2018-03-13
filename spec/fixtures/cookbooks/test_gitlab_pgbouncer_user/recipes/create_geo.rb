pgbouncer_user 'geo' do
  pg_helper GeoPgHelper.new(node)
  user 'pgbouncer-geo'
  password 'fakepassword-geo'
  database 'fakedb-geo'
  add_auth_function true
  action :create
end
