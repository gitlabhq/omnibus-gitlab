#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# pgbouncer_user and pgbouncer_user_password are settings for the account
# pgbouncer will use to authenticate to the database.

pgb_helper = PgbouncerHelper.new(node)
default_auth_query = node.default['pgbouncer']['auth_query']
auth_query = node['pgbouncer']['auth_query']

if pgb_helper.create_pgbouncer_user?('geo-postgresql')
  pgbouncer_user 'geo' do
    helper lazy { GeoPgHelper.new(node) }
    user node['gitlab']['geo_postgresql']['pgbouncer_user']
    password node['gitlab']['geo_postgresql']['pgbouncer_user_password']
    database node['gitlab']['geo_secondary']['db_database']
    add_auth_function default_auth_query.eql?(auth_query)
    action :create
  end
end

if pgb_helper.create_pgbouncer_user?('postgresql') || pgb_helper.create_pgbouncer_user?('patroni')
  ignored_databases = %w[geo]
  database_host = node['gitlab']['gitlab_rails']['db_host']
  databases = node['gitlab']['gitlab_rails']['databases'].select { |db, details| details['enable'] && details['db_host'] == database_host && !ignored_databases.include?(db) }

  databases.each do |db, settings|
    pgbouncer_user "rails:#{db}" do
      helper lazy { PgHelper.new(node) }
      user node['postgresql']['pgbouncer_user']
      password node['postgresql']['pgbouncer_user_password']
      database settings['db_database']
      add_auth_function default_auth_query.eql?(auth_query)
      action :create
    end
  end

  # Currently we do not create registry pgbouncer user when patroni is enabled.
  if !pgb_helper.create_pgbouncer_user?('patroni') && node.dig('postgresql', 'registry', 'auto_create')
    pgbouncer_user 'registry' do
      helper lazy { PgHelper.new(node) }
      user node['postgresql']['pgbouncer_user']
      password node['postgresql']['pgbouncer_user_password']
      database node['postgresql']['registry']['dbname']
      add_auth_function default_auth_query.eql?(auth_query)
      action :create
    end
  end

  # Auto-instantiate the pgbouncer auth function (pg_shadow_lookup) for
  # every database in the component database registry. The actual PG user
  # owning each database is created by postgresql::managed_databases; the
  # resource below is responsible only for the pgbouncer-side auth path.
  ComponentDatabaseRegistry.enabled_entries(node['postgresql']['component_databases']).each do |key, entry|
    db_name = entry['database'] || key

    pgbouncer_user "component:#{key}" do
      helper lazy { PgHelper.new(node) }
      user node['postgresql']['pgbouncer_user']
      password node['postgresql']['pgbouncer_user_password']
      database db_name
      add_auth_function default_auth_query.eql?(auth_query)
      action :create
    end
  end
end
