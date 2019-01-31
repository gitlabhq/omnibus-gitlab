postgresql_fdw 'gitlab_secondary' do
  db_name 'foobar'
  external_host '127.0.0.1'
  external_port 1234
  external_name 'lorem'

  action :delete
end
