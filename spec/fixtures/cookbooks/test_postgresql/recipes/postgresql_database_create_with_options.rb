postgresql_database 'fakedb' do
  database_port 9999
  database_socket '/fake/dir'
  owner 'fakeuser'
end
