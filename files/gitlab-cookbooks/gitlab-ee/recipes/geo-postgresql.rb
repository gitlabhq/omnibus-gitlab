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
include_recipe 'postgresql::bin'
include_recipe 'postgresql::user'
include_recipe 'postgresql::sysctl'

account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('geo-postgresql')

postgresql_username = account_helper.postgresql_user
postgresql_data_dir = File.join(node['gitlab']['geo_postgresql']['dir'], 'data')

geo_pg_helper = GeoPgHelper.new(node)

database_version = geo_pg_helper.pinned_postgresql_version || geo_pg_helper.database_version || geo_pg_helper.version

directory node['gitlab']['geo_postgresql']['dir'] do
  owner postgresql_username
  mode '0755'
  recursive true
end

directory postgresql_data_dir do
  owner postgresql_username
  mode '0700'
  recursive true
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

execute "/opt/gitlab/embedded/bin/initdb -D #{postgresql_data_dir} -E UTF8" do
  user postgresql_username
  not_if { geo_pg_helper.bootstrapped? }
end

postgresql_config = File.join(postgresql_data_dir, 'postgresql.conf')
postgresql_runtime_config = File.join(postgresql_data_dir, 'runtime.conf')
bootstrapping = !geo_pg_helper.bootstrapped?
should_notify = omnibus_helper.should_notify?('geo-postgresql') && !bootstrapping

template postgresql_config do
  source 'postgresql.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { geo_pg_helper }
  variables(node['gitlab']['geo_postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

template postgresql_runtime_config do
  source 'postgresql-runtime.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { geo_pg_helper }
  variables(node['gitlab']['geo_postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :run, 'execute[reload geo-postgresql]', :immediately if should_notify
end

pg_hba_config = File.join(postgresql_data_dir, 'pg_hba.conf')

template pg_hba_config do
  source 'pg_hba.conf.erb'
  owner postgresql_username
  mode '0644'
  variables(lazy { node['gitlab']['geo_postgresql'].to_hash })
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

template File.join(postgresql_data_dir, 'pg_ident.conf') do
  owner postgresql_username
  mode '0644'
  variables(node['gitlab']['geo_postgresql'].to_hash)
  cookbook 'postgresql'
  notifies :restart, 'runit_service[geo-postgresql]', :immediately if should_notify
end

runit_service 'geo-postgresql' do
  start_down node['gitlab']['geo_postgresql']['ha']
  restart_on_update false
  control(['t'])
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    database_version: database_version.major
  }.merge(params))
  log_options logging_settings[:options]
end

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

geo_pg_port = node['gitlab']['geo_postgresql']['port']
geo_pg_user = node['gitlab']['geo_postgresql']['sql_user']
geo_pg_user_password = node['gitlab']['geo_postgresql']['sql_user_password']
geo_database_name = node['gitlab']['geo_secondary']['db_database']

if node['gitlab']['geo_postgresql']['enable']
  postgresql_user geo_pg_user do
    password "md5#{geo_pg_user_password}" unless geo_pg_user_password.nil?
    helper geo_pg_helper
    action :create
  end

  postgresql_database geo_database_name do
    owner geo_pg_user
    database_port geo_pg_port
    database_socket node['gitlab']['geo_postgresql']['unix_socket_directory']
    helper geo_pg_helper
    action :create
  end

  postgresql_extension 'pg_trgm' do
    database geo_database_name
    helper geo_pg_helper
    action :enable
  end

  version_file 'Create version file for PostgreSQL' do
    version_file_path File.join(node['gitlab']['geo_postgresql']['dir'], 'VERSION')
    version_check_cmd "/opt/gitlab/embedded/bin/postgres --version"
    notifies :restart, 'runit_service[geo-postgresql]', :immediately if node['gitlab']['geo_postgresql']['auto_restart_on_version_change'] && geo_pg_helper.is_running? && should_notify
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
    not_if { node['gitlab']['geo_postgresql']['auto_restart_on_version_change'] }
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
