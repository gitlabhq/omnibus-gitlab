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

require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/pgbouncer"
require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql"

add_command_under_category('pgb-console', 'pgbouncer', 'Connect to the pgbouncer console', 2) do
  pgb = get_client
  pgb.console
end

add_command_under_category('pgb-notify', 'pgbouncer', 'Notify pgbouncer of an update to its database', 2) do
  pgb = get_client
  pgb.notify
end

add_command_under_category('pgb-suspend', 'pgbouncer', 'Send the "suspend" command to pgbouncer', 2) do
  pgb = get_client
  pgb.suspend
end

add_command_under_category('pgb-resume', 'pgbouncer', 'Send the "resume" command to pgbouncer', 2) do
  pgb = get_client
  pgb.resume
end

add_command_under_category('pgb-kill', 'pgbouncer', 'Send the "resume" command to pgbouncer', 2) do
  pgb = get_client
  if pgb.options['pg_database'].nil?
    $stderr.puts "Must provide database name to kill"
    Kernel.exit 1
  end
  pgb.kill
end

add_command_under_category('write-pgpass', 'database', 'Write a pgpass file for the specified user', 2) do
  begin
    password = GitlabCtl::Util.get_password
  rescue GitlabCtl::Errors::PasswordMismatch
    $stderr.puts "Passwords do not match"
    Kernel.exit 1
  end

  options = get_pg_options

  pgpass = GitlabCtl::PostgreSQL::Pgpass.new(
    hostname: options['host'],
    port: options['port'],
    database: options['database'],
    username: options['user'],
    password: password,
    host_user: options['host_user'],
    host_group: options['host_group']
  )
  pgpass.write
end

def get_pg_options
  options = {
    'database' => 'gitlabhq_production',
    'databases_ini' => nil,
    'databases_json' => nil,
    'host' => nil,
    'port' => nil,
    'user' => 'pgbouncer',
    'pg_database' => nil,
    'newhost' => nil,
    'host_user' => nil,
    'host_group' => nil
  }

  OptionParser.new do |opts|
    opts.on('--database NAME', 'Name of the database to connect to') do |d|
      options['database'] = d
    end

    opts.on('--host HOSTNAME', 'Host the database runs on ') do |h|
      options['host'] = h
    end

    opts.on('--port PORT', 'Port the database is listening on') do |p|
      options['port'] = p
    end

    opts.on('--user USERNAME', 'User to connect to the database as') do |u|
      options['user'] = u
    end

    opts.on('--hostuser USERNAME', 'User to write the pgpass file for') do |h|
      options['host_user'] = h
    end

    opts.on('--hostgroup GROUP', 'Group to write the pgpass file for') do |h|
      options['host_group'] = h
    end

    opts.on('--pg-database DATABASE', 'Pgbouncer database to modify') do |db|
      options['pg_database'] = db
    end

    opts.on('--pg-host HOST', 'Host that pgbouncer is running on') do |h|
      options['pg_host'] = h
    end

    opts.on('--pg-port PORT', 'Port that pgbouncer is listening on') do |p|
      options['pg_port'] = p
    end

    opts.on('--newhost HOSTNAME', 'The new master when updating pgbouncer') do |h|
      options['newhost'] = h
    end

    opts.on('--databases-json JSON', 'The location of the databases.json file') do |j|
      options['databases_json'] = j
    end

    opts.on('--databases-ini JSON', 'The location of the databases.json file') do |j|
      options['databases_ini'] = j
    end
  end.parse!(ARGV)
  options
end

def get_client
  begin
    pgb = Pgbouncer::Databases.new(get_pg_options, base_path, data_path)
  rescue RuntimeError => e
    log e.message
    exit 1
  end
  pgb
end
