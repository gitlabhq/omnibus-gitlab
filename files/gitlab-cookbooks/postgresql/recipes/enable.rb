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
include_recipe 'postgresql::bin'
include_recipe 'postgresql::user'
include_recipe 'postgresql::sysctl'

account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
pg_helper = PgHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('postgresql')
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group
postgresql_data_dir = File.join(node['postgresql']['dir'], "data")

directory node['postgresql']['dir'] do
  owner postgresql_username
  mode "0755"
  recursive true
end

[
  postgresql_data_dir,
  pg_helper.config_dir
].each do |dir|
  directory dir do
    owner postgresql_username
    mode "0700"
    recursive true
  end
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
  not_if { pg_helper.bootstrapped? || pg_helper.delegated? }
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
# Create SSL cert + key in the defined location. Paths are relative to postgresql_data_dir
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
  helper pg_helper
  notifies :run, 'execute[reload postgresql]', :immediately if omnibus_helper.should_notify?('postgresql') && !pg_helper.delegated?
  notifies :run, 'execute[start postgresql]', :immediately if omnibus_helper.service_dir_enabled?('postgresql') && !pg_helper.delegated?
end

include_recipe 'postgresql::standalone' unless pg_helper.delegated?
