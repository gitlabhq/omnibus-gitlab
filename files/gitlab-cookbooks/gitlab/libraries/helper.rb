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

require 'mixlib/shellout'

class PgHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def is_running?
    OmnibusHelper.service_up?("postgresql")
  end

  def database_exists?(db_name)
    psql_cmd(["-d 'template1'",
              "-c 'select datname from pg_database' -A",
              "| grep -x #{db_name}"])
  end

  def sql_user_exists?
    user_exists?(node['gitlab']['postgresql']['sql_user'])
  end

  def user_exists?(db_user)
    psql_cmd(["-d 'template1'",
              "-c 'select usename from pg_user' -A",
              "|grep -x #{db_user}"])
  end

  def psql_cmd(cmd_list)
    cmd = ["/opt/gitlab/embedded/bin/chpst",
           "-u #{pg_user}",
           "/opt/gitlab/embedded/bin/psql",
           "--port #{pg_port}",
           cmd_list.join(" ")].join(" ")
    do_shell_out(cmd, 0)
  end

  def pg_user
    node['gitlab']['postgresql']['username']
  end

  def pg_port
    node['gitlab']['postgresql']['port']
  end

  def do_shell_out(cmd, expect_status)
    o = Mixlib::ShellOut.new(cmd)
    o.run_command
    o.exitstatus == expect_status
  end

end

class OmnibusHelper

  def self.should_notify?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name)
  end

  def self.service_up?(service_name)
    o = Mixlib::ShellOut.new("/opt/gitlab/bin/gitlab-ctl status #{service_name}")
    o.run_command
    o.exitstatus == 0
  end

end

module SingleQuoteHelper

  def single_quote(string)
   "'#{string}'" unless string.nil?
  end

end
