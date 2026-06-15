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
end
