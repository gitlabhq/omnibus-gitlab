# pgbouncer Cookbook

## Resources

### pgbouncer_user

Creates and configures a pgbouncer user

#### properties

`type` (name property): The identifier
`account_helper`: defaults to AccountHelper.new(node)
`add_auth_function`: whether or not to add the auth function, true or false.
`database`: name of the db
`password`: pgobuncer password
`helper`: defaults to PgHelper.new(node)
`user`: pgbouncer username

#### example

```ruby
pgbouncer_user 'rails' do
  pgbouncer_user 'pgbouncer'
  pgbouncer_user_password 'password'
  db_database 'gitlabhq_production'
  cmd "/opt/gitlab/bin/gitlab-psql"
  add_auth_function 'yes'
  action :create
end
```
