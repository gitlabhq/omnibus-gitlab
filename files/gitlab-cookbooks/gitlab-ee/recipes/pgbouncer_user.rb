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

account_helper = AccountHelper.new(node)
pg_helper = PgHelper.new(node)

database = node['gitlab']['gitlab-rails']['db_database']

postgresql_user node['gitlab']['postgresql']['pgbouncer_user'] do
  password "md5#{node['gitlab']['postgresql']['pgbouncer_user_password']}"
  action :create
end

pgbouncer_auth_function = pg_helper.pg_shadow_lookup

execute 'Add pgbouncer auth function' do
  command %(/opt/gitlab/bin/gitlab-psql -d #{database} -c '#{pgbouncer_auth_function}')
  user account_helper.postgresql_user
  not_if { pg_helper.has_function?(database, "pg_shadow_lookup") }
  only_if { node.default['gitlab']['pgbouncer']['auth_query'].eql?(node['gitlab']['pgbouncer']['auth_query']) }
end
