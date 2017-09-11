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
pgb_helper = PgbouncerHelper.new(node)

include_recipe 'gitlab::postgresql_user'

[
  node['gitlab']['pgbouncer']['log_directory'],
  node['gitlab']['pgbouncer']['data_directory']
].each do |dir|
  directory dir do
    owner account_helper.postgresql_user
    mode '0700'
    recursive true
  end
end

template "#{node['gitlab']['pgbouncer']['data_directory']}/pg_auth" do
  source "pg_auth.erb"
  variables node['gitlab']['pgbouncer'].to_hash
end

runit_service 'pgbouncer' do
  options(
    username: node['gitlab']['postgresql']['username'],
    data_directory: node['gitlab']['pgbouncer']['data_directory'],
    log_directory: node['gitlab']['pgbouncer']['log_directory']
  )
end

template "#{node['gitlab']['pgbouncer']['data_directory']}/pgbouncer.ini" do
  source "#{File.basename(name)}.erb"
  variables lazy { node['gitlab']['pgbouncer'].to_hash }
  notifies :run, 'execute[reload pgbouncer]', :immediately
end

template node['gitlab']['pgbouncer']['databases_ini'] do
  source "#{File.basename(name)}.erb"
  user node['gitlab']['pgbouncer']['databases_ini_user']
  variables lazy { node['gitlab']['pgbouncer'].to_hash }
  notifies :run, 'execute[reload pgbouncer]', :immediately
end

execute 'reload pgbouncer' do
  command '/opt/gitlab/embedded/bin/sv hup pgbouncer'
  action :nothing
end
