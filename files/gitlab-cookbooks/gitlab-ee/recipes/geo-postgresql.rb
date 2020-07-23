#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2017 GitLab Inc.
# License:: Apache License, Version 2.0
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
omnibus_helper = OmnibusHelper.new(node)

postgresql_log_dir = node['gitlab']['geo-postgresql']['log_directory']
postgresql_username = account_helper.postgresql_user

geo_pg_helper = GeoPgHelper.new(node)
fdw_helper = FdwHelper.new(node)

include_recipe 'postgresql::user'

directory node['gitlab']['geo-postgresql']['dir'] do
  owner postgresql_username
  mode '0755'
  recursive true
end

[
  node['gitlab']['geo-postgresql']['data_dir'],
  postgresql_log_dir
].each do |dir|
  directory dir do
    owner postgresql_username
    mode '0700'
    recursive true
  end
end

execute "/opt/gitlab/embedded/bin/initdb -D #{node['gitlab']['geo-postgresql']['data_dir']} -E UTF8" do
  user postgresql_username
  not_if { geo_pg_helper.bootstrapped? }
end

postgresql_config = File.join(node['gitlab']['geo-postgresql']['data_dir'], 'postgresql.conf')
postgresql_runtime_config = File.join(node['gitlab']['geo-postgresql']['data_dir'], 'runtime.conf')
bootstrapping = !geo_pg_helper.bootstrapped?
should_notify = omnibus_helper.should_notify?('geo-postgresql') && !bootstrapping

template postgresql_config do
  source 'postgresql.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { geo_pg_helper }
  variables(node['gitlab']['geo-postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

template postgresql_runtime_config do
  source 'postgresql-runtime.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { geo_pg_helper }
  variables(node['gitlab']['geo-postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :run, 'execute[reload geo-postgresql]', :immediately if should_notify
end

pg_hba_config = File.join(node['gitlab']['geo-postgresql']['data_dir'], 'pg_hba.conf')

template pg_hba_config do
  source 'pg_hba.conf.erb'
  owner postgresql_username
  mode '0644'
  variables(lazy { node['gitlab']['geo-postgresql'].to_hash })
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

template File.join(node['gitlab']['geo-postgresql']['data_dir'], 'pg_ident.conf') do
  owner postgresql_username
  mode '0644'
  variables(node['gitlab']['geo-postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

runit_service 'geo-postgresql' do
  start_down node['gitlab']['geo-postgresql']['ha']
  restart_on_update false
  control(['t'])
  options({
    log_directory: postgresql_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['geo-postgresql'].to_hash)
end

# This recipe must be ran BEFORE any calls to the binaries are made
# and AFTER the service has been defined
# to ensure the correct running version of PostgreSQL
# Only exception to this rule is "initdb" call few lines up because this should
# run only on new installation at which point we expect to have correct binaries.
include_recipe 'postgresql::bin'

execute 'start geo-postgresql' do
  command '/opt/gitlab/bin/gitlab-ctl start geo-postgresql'
  retries 20
  action :nothing unless bootstrapping
end

###
# Create the database, migrate it, and create the users we need, and grant them
# privileges.
###

# This template is needed to make the gitlab-geo-psql script and GeoPgHelper work
template '/opt/gitlab/etc/gitlab-geo-psql-rc' do
  owner 'root'
  group 'root'
end

geo_pg_port = node['gitlab']['geo-postgresql']['port']
geo_pg_user = node['gitlab']['geo-postgresql']['sql_user']
geo_pg_user_password = node['gitlab']['geo-postgresql']['sql_user_password']
geo_database_name = node['gitlab']['geo-secondary']['db_database']

# set custom pg_hba entries at the secondary postgres for FDW compatibility
node.default['postgresql']['custom_pg_hba_entries']['fdw'] = fdw_helper.pg_hba_entries if fdw_helper.fdw_enabled?

if node['gitlab']['geo-postgresql']['enable']
  postgresql_user geo_pg_user do
    password "md5#{geo_pg_user_password}" unless geo_pg_user_password.nil?
    helper geo_pg_helper
    action :create
  end

  postgresql_database geo_database_name do
    owner geo_pg_user
    database_port geo_pg_port
    database_socket node['gitlab']['geo-postgresql']['unix_socket_directory']
    helper geo_pg_helper
    action :create
  end

  postgresql_extension 'pg_trgm' do
    database geo_database_name
    helper geo_pg_helper
    action :enable
  end

  postgresql_schema 'gitlab_secondary' do
    database geo_database_name
    owner geo_pg_user
    helper geo_pg_helper
    action :create
    only_if { fdw_helper.fdw_enabled? && !fdw_helper.fdw_password.nil? }
  end

  postgresql_fdw 'gitlab_secondary' do
    db_name geo_database_name
    external_host fdw_helper.fdw_host
    external_port fdw_helper.fdw_port
    external_name fdw_helper.fdw_dbname
    helper geo_pg_helper
    action :create
    only_if { fdw_helper.fdw_enabled? && !fdw_helper.fdw_password.nil? }
  end

  postgresql_fdw_user_mapping 'gitlab_secondary' do
    db_user geo_pg_user
    db_name geo_database_name
    external_user fdw_helper.fdw_user
    external_password fdw_helper.fdw_password
    helper geo_pg_helper
    action :create
    only_if { fdw_helper.fdw_enabled? && !fdw_helper.fdw_password.nil? }
  end

  execute 'refresh foreign table definition' do
    command '/opt/gitlab/bin/gitlab-rake geo:db:refresh_foreign_tables'
    returns [0, 1]

    only_if { fdw_helper.fdw_can_refresh? }
  end

  ruby_block 'warn pending geo-postgresql restart' do
    block do
      message = <<~MESSAGE
        The version of the running geo-postgresql service is different than what is installed.
        Please restart geo-postgresql to start the new version.

        sudo gitlab-ctl restart geo-postgresql
      MESSAGE
      LoggingHelper.warning(message)
    end
    only_if { geo_pg_helper.is_running? && geo_pg_helper.running_version != geo_pg_helper.version }
  end
end

execute 'reload geo-postgresql' do
  command %(/opt/gitlab/bin/gitlab-ctl hup geo-postgresql)
  retries 20
  action :nothing
  only_if { geo_pg_helper.is_running? }
end

execute 'start geo-postgresql again' do
  command %(/opt/gitlab/bin/gitlab-ctl start geo-postgresql)
  retries 20
  action :nothing
  not_if { geo_pg_helper.is_running? }
end
