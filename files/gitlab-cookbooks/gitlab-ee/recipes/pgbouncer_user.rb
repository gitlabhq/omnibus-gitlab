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
default_auth_query = node.default['gitlab']['pgbouncer']['auth_query']
auth_query = node['gitlab']['pgbouncer']['auth_query']

if pgb_helper.create_pgbouncer_user?('geo-postgresql')
  pgbouncer_user 'geo' do
    pg_helper GeoPgHelper.new(node)
    user node['gitlab']['geo-postgresql']['pgbouncer_user']
    password node['gitlab']['geo-postgresql']['pgbouncer_user_password']
    database node['gitlab']['geo-secondary']['db_database']
    add_auth_function default_auth_query.eql?(auth_query)
    action :create
  end
end

if pgb_helper.create_pgbouncer_user?('postgresql') || pgb_helper.create_pgbouncer_user?('patroni')
  pgbouncer_user 'rails' do
    pg_helper PgHelper.new(node)
    user node['postgresql']['pgbouncer_user']
    password node['postgresql']['pgbouncer_user_password']
    database node['gitlab']['gitlab-rails']['db_database']
    add_auth_function default_auth_query.eql?(auth_query)
    action :create
  end
end
