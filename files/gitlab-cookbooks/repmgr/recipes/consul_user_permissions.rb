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
repmgr_db = node['repmgr']['database']

postgresql_user account_helper.consul_user do
  notifies :run, "execute[grant read only access to repmgr]"
  only_if { pg_helper.is_running? && !pg_helper.user_exists?(account_helper.consul_user) }
end

select_query = %(GRANT SELECT, DELETE ON ALL TABLES IN SCHEMA repmgr_#{node['repmgr']['cluster']} TO "#{node['consul']['username']}")
usage_query = %(GRANT USAGE ON SCHEMA repmgr_#{node['repmgr']['cluster']} TO "#{node['consul']['username']}")

execute "grant read only access to repmgr" do
  command %(gitlab-psql -d #{repmgr_db} -c '#{select_query}; #{usage_query};')
  user account_helper.postgresql_user
  only_if { pg_helper.is_running? && pg_helper.database_exists?(repmgr_db) }
  action :nothing
end
