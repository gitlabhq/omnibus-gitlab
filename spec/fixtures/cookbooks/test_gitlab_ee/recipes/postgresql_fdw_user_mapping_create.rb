postgresql_fdw_user_mapping 'gitlab_secondary' do
  db_name 'foobar'
  db_user 'randomuser'
  external_user 'externaluser'
  external_password 'externalpassword'
end
