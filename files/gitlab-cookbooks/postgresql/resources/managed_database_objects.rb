# Copyright:: Copyright (c) 2026 GitLab Inc.
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

unified_mode true

property :database_name, String, name_property: true
property :config, Hash, required: true
property :pg_helper, PgHelper, required: true, sensitive: true

action :create do
  username = new_resource.config['user']
  password = new_resource.config['password']
  owner = new_resource.config['owner'] || username
  extensions = new_resource.config['extensions'] || []

  postgresql_user username do
    password "md5#{password}" unless password.nil?
    action :create
  end

  # When `owner` differs from `user`, create the owner role without a
  # password so the subsequent `CREATE DATABASE ... OWNER <owner>`
  # succeeds even on a fresh cluster. Privileged owner roles in PG
  # conventionally use peer or trust auth rather than md5; operators
  # who need an md5 secret on the owner can layer it via
  # `ALTER USER` or by supplying it through `extra_config_command`
  # plus a follow-up resource.
  if owner != username
    postgresql_user owner do
      action :create
    end
  end

  postgresql_database new_resource.database_name do
    database_socket node['postgresql']['unix_socket_directory']
    database_port node['postgresql']['port']
    owner owner
    helper new_resource.pg_helper
    action :create
  end

  extensions.each do |ext_name|
    postgresql_extension ext_name do
      database new_resource.database_name
      action :enable
    end
  end

  # pgbouncer only needs CONNECT to a component database when it actually pools
  # it: pgbouncer active (its password is set) AND pool_component_databases on.
  # `pool_component_databases` defaults to true in
  # files/gitlab-cookbooks/pgbouncer/attributes/default.rb (shipped with the
  # component-database framework) and is the same gate pgbouncer::enable uses to
  # add component databases to the pool, so this mirrors real pooling behavior.
  pgbouncer_pools = !node['postgresql']['pgbouncer_user_password'].nil? && node.dig('pgbouncer', 'pool_component_databases')
  pgbouncer_user = pgbouncer_pools ? node['postgresql']['pgbouncer_user'] : nil

  connect_users = [username]
  connect_users << owner if owner != username

  postgresql_database_access new_resource.database_name do
    connect_users connect_users
    pgbouncer_user pgbouncer_user
    pg_helper new_resource.pg_helper
    action :enforce
  end
end
