#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

include_recipe 'postgresql::directory_locations'

postgresql_log_dir = node['postgresql']['log_directory']
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group
postgresql_data_dir_symlink = File.join(node['postgresql']['dir'], "data")

pg_helper = PgHelper.new(node)

include_recipe 'postgresql::user'

directory node['postgresql']['dir'] do
  owner postgresql_username
  mode "0755"
  recursive true
end

[
  node['postgresql']['data_dir'],
  postgresql_log_dir,
  pg_helper.config_dir
].each do |dir|
  directory dir do
    owner postgresql_username
    mode "0700"
    recursive true
  end
end

link postgresql_data_dir_symlink do
  to node['postgresql']['data_dir']
  not_if { node['postgresql']['data_dir'] == postgresql_data_dir_symlink }
end

include_recipe "package::sysctl"

gitlab_sysctl "kernel.shmmax" do
  value node['postgresql']['shmmax']
end

gitlab_sysctl "kernel.shmall" do
  value node['postgresql']['shmall']
end

sem = [
  node['postgresql']['semmsl'],
  node['postgresql']['semmns'],
  node['postgresql']['semopm'],
  node['postgresql']['semmni'],
].join(" ")
gitlab_sysctl "kernel.sem" do
  value sem
end

execute "/opt/gitlab/embedded/bin/initdb -D #{node['postgresql']['data_dir']} -E UTF8" do
  user postgresql_username
  not_if { pg_helper.bootstrapped? || pg_helper.delegated? }
end

# This template is needed to make the gitlab-psql script and PgHelper work
template "/opt/gitlab/etc/gitlab-psql-rc" do
  owner 'root'
  group 'root'
end

# IMPORTANT NOTE:
#
# When PostgreSQL configuration is delegated, e.g. to Patroni, some of the following tasks will be skipped or
# executed with a different setting. In particular, configuration templates and SSL files will be rendered into
# a different directory.
#
# The module that is in control of the PostgreSQL configuration, e.g. Patroni, is responsible for the proper
# configuration of the database.

##
# Create SSL cert + key in the defined location. Paths are relative to node['postgresql']['data_dir']
##
file pg_helper.ssl_cert_file do
  content node['postgresql']['internal_certificate']
  owner postgresql_username
  group postgresql_group
  mode lazy { node['patroni']['use_pg_rewind'] ? 0600 : 0400 }
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

file pg_helper.ssl_key_file do
  content node['postgresql']['internal_key']
  owner postgresql_username
  group postgresql_group
  mode lazy { node['patroni']['use_pg_rewind'] ? 0600 : 0400 }
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

postgresql_config 'gitlab' do
  pg_helper pg_helper
  notifies :run, 'execute[reload postgresql]', :immediately if omnibus_helper.should_notify?('postgresql') && !pg_helper.delegated?
  notifies :run, 'execute[start postgresql]', :immediately if omnibus_helper.service_dir_enabled?('postgresql') && !pg_helper.delegated?
end

# Skip the following steps when PostgreSQL configuration is delegated, e.g. to Patroni
return if pg_helper.delegated?

runit_service "postgresql" do
  start_down node['postgresql']['ha']
  supervisor_owner postgresql_username
  supervisor_group postgresql_group
  restart_on_update false
  control(['t'])
  options({
    log_directory: postgresql_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['postgresql'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgresql" do
    retries 20
  end
end

###
# Create the database, migrate it, and create the users we need, and grant them
# privileges.
###

database_objects 'postgresql' do
  pg_helper pg_helper
  account_helper account_helper
  not_if { pg_helper.replica? }
end

ruby_block 'warn pending postgresql restart' do
  block do
    message = <<~MESSAGE
      The version of the running postgresql service is different than what is installed.
      Please restart postgresql to start the new version.

      sudo gitlab-ctl restart postgresql
    MESSAGE
    LoggingHelper.warning(message)
  end
  only_if { pg_helper.is_running? && pg_helper.running_version != pg_helper.version }
end

execute 'reload postgresql' do
  command %(/opt/gitlab/bin/gitlab-ctl hup postgresql)
  retries 20
  action :nothing
  only_if { pg_helper.is_running? }
end

execute 'start postgresql' do
  command %(/opt/gitlab/bin/gitlab-ctl start postgresql)
  retries 20
  action :nothing
  not_if { pg_helper.is_running? }
end
