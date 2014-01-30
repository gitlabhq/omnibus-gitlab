#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

postgresql_dir = node['gitlab']['postgresql']['dir']
postgresql_data_dir = node['gitlab']['postgresql']['data_dir']
postgresql_data_dir_symlink = File.join(postgresql_dir, "data")
postgresql_log_dir = node['gitlab']['postgresql']['log_directory']
chef_db_dir = Dir.glob("/opt/gitlab/embedded/service/erchef/lib/chef_db-*").first

user node['gitlab']['postgresql']['username'] do
  system true
  shell node['gitlab']['postgresql']['shell']
  home node['gitlab']['postgresql']['home']
end

directory postgresql_log_dir do
  owner node['gitlab']['postgresql']['username']
  recursive true
end

directory postgresql_dir do
  owner node['gitlab']['postgresql']['username']
  mode "0700"
end

directory postgresql_data_dir do
  owner node['gitlab']['postgresql']['username']
  mode "0700"
  recursive true
end

link postgresql_data_dir_symlink do
  to postgresql_data_dir
  not_if { postgresql_data_dir == postgresql_data_dir_symlink }
end

file File.join(node['gitlab']['postgresql']['home'], ".profile") do
  owner node['gitlab']['postgresql']['username']
  mode "0644"
  content <<-EOH
PATH=#{node['gitlab']['postgresql']['user_path']}
EOH
end

if File.directory?("/etc/sysctl.d") && File.exists?("/etc/init.d/procps")
  # smells like ubuntu...
  service "procps" do
    action :nothing
  end

  template "/etc/sysctl.d/90-postgresql.conf" do
    source "90-postgresql.conf.sysctl.erb"
    owner "root"
    mode  "0644"
    variables(node['gitlab']['postgresql'].to_hash)
    notifies :start, 'service[procps]', :immediately
  end
else
  # hope this works...
  execute "sysctl" do
    command "/sbin/sysctl -p /etc/sysctl.conf"
    action :nothing
  end

  bash "add shm settings" do
    user "root"
    code <<-EOF
      echo 'kernel.shmmax = #{node['gitlab']['postgresql']['shmmax']}' >> /etc/sysctl.conf
      echo 'kernel.shmall = #{node['gitlab']['postgresql']['shmall']}' >> /etc/sysctl.conf
    EOF
    notifies :run, 'execute[sysctl]', :immediately
    not_if "egrep '^kernel.shmmax = ' /etc/sysctl.conf"
  end
end

execute "/opt/gitlab/embedded/bin/initdb -D #{postgresql_data_dir}" do
  user node['gitlab']['postgresql']['username']
  not_if { File.exists?(File.join(postgresql_data_dir, "PG_VERSION")) }
end

postgresql_config = File.join(postgresql_data_dir, "postgresql.conf")

template postgresql_config do
  source "postgresql.conf.erb"
  owner node['gitlab']['postgresql']['username']
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]' if OmnibusHelper.should_notify?("postgresql")
end

pg_hba_config = File.join(postgresql_data_dir, "pg_hba.conf")

template pg_hba_config do
  source "pg_hba.conf.erb"
  owner node['gitlab']['postgresql']['username']
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]' if OmnibusHelper.should_notify?("postgresql")
end

should_notify = OmnibusHelper.should_notify?("postgresql")

runit_service "postgresql" do
  down node['gitlab']['postgresql']['ha']
  control(['t'])
  options({
    :log_directory => postgresql_log_dir,
    :svlogd_size => node['gitlab']['postgresql']['svlogd_size'],
    :svlogd_num  => node['gitlab']['postgresql']['svlogd_num']
  }.merge(params))
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
pg_helper = PgHelper.new(node)
pg_port = node['gitlab']['postgresql']['port']
pg_user = node['gitlab']['postgresql']['username']
bin_dir = "/opt/gitlab/embedded/bin"
db_name = "opscode_chef"

execute "create #{db_name} database" do
  command "#{bin_dir}/createdb -T template0 --port #{pg_port} -E UTF-8 #{db_name}"
  user pg_user
  not_if { !pg_helper.is_running? || pg_helper.database_exists?(db_name) }
  retries 30
  notifies :run, "execute[migrate_database]", :immediately
end

execute "migrate_database" do
  command "#{bin_dir}/psql #{db_name} --port #{pg_port} < priv/pgsql_schema.sql"
  cwd chef_db_dir
  user pg_user
  action :nothing
end

sql_user        = node['gitlab']['postgresql']['sql_user']
sql_user_passwd = node['gitlab']['postgresql']['sql_password']

execute "#{bin_dir}/psql --port #{pg_port} -d '#{db_name}' -c \"CREATE USER #{sql_user} WITH SUPERUSER ENCRYPTED PASSWORD '#{sql_user_passwd}'\"" do
  cwd chef_db_dir
  user pg_user
  notifies :run, "execute[grant #{db_name} privileges]", :immediately
  not_if { !pg_helper.is_running? || pg_helper.sql_user_exists? }
end

execute "grant #{db_name} privileges" do
  command "#{bin_dir}/psql --port #{pg_port} -d '#{db_name}' -c \"GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO #{sql_user}\""
  user pg_user
  action :nothing
end

sql_ro_user = node['gitlab']['postgresql']['sql_ro_user']
sql_ro_user_passwd = node['gitlab']['postgresql']['sql_ro_password']

execute "#{bin_dir}/psql --port #{pg_port} -d '#{db_name}' -c \"CREATE USER #{sql_ro_user} WITH SUPERUSER ENCRYPTED PASSWORD '#{sql_ro_user_passwd}'\"" do
  cwd chef_db_dir
  user pg_user
  notifies :run, "execute[grant #{db_name}_ro privileges]", :immediately
  not_if { !pg_helper.is_running? || pg_helper.sql_ro_user_exists? }
end

execute "grant #{db_name}_ro privileges" do
  command "#{bin_dir}/psql --port #{pg_port} -d '#{db_name}' -c \"GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO #{sql_ro_user}\""
  user pg_user
  action :nothing
end
