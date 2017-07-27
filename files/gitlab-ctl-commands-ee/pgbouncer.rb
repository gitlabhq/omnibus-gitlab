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

require "#{base_path}/embedded/service/omnibus-ctl/lib/pgbouncer"

add_command_under_category('pgb-notify', 'pgbouncer', 'Notify pgbouncer of an update to its database', 2) do |_cmd, _args|
  begin
    pgb = Pgbouncer::Databases.new(get_pg_options, base_path, data_path)
  rescue RuntimeError => rte
    log rte.message
    exit 1
  end
  pgb.notify
end

def get_pg_options
  database = 'gitlabhq_production'
  options = {
    'host' => nil,
    'port' => 5432,
    'user' => 'pgbouncer'
  }

  OptionParser.new do |opts|
    opts.on('--database NAME', 'Name of the database to connect to') do |d|
      database = d
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
  end.parse!(ARGV)
  { database => options }
end
