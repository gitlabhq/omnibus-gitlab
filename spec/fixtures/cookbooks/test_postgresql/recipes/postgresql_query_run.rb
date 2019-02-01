require_relative '../../../../../files/gitlab-cookbooks/gitlab/libraries/helpers/geo_pg_helper'

postgresql_query 'create schema' do
  db_name 'omnibus_test'
  query "CREATE SCHEMA example AUTHORIZATION foobar;"
end

postgresql_query 'create schema' do
  db_name 'omnibus_test'
  query "CREATE SCHEMA example AUTHORIZATION foobar;"
  helper GeoPgHelper.new(node)
end
