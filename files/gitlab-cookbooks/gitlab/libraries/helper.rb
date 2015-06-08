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

  def self.not_listening?(service_name)
    File.exists?("/opt/gitlab/service/#{service_name}/down") && service_down?(service_name)
  end

  def self.service_up?(service_name)
    o = Mixlib::ShellOut.new("/opt/gitlab/bin/gitlab-ctl status #{service_name}")
    o.run_command
    o.exitstatus == 0
  end

  def self.service_down?(service_name)
    o = Mixlib::ShellOut.new("/opt/gitlab/bin/gitlab-ctl status #{service_name}")
    o.run_command
    o.exitstatus == 3
  end

end

class CiHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    require 'yaml'
    credentials_file = "/var/opt/gitlab/gitlab-ci/etc/gitlab_server.yml"

    if File.exists?(credentials_file)
      Chef::Log.debug("Reading the CI credentials file at #{credentials_file}")
      Chef::Log.debug("If you need to change app_id and app_secret use gitlab.rb.")
      gitlab_server = YAML::load_file(credentials_file)
      app_id = gitlab_server[:app_id]
      app_secret = gitlab_server[:app_secret]
    else
      Chef::Log.debug("Didn't find #{credentials_file}, connecting to database to generate new app_id and app_secret.")
      cmd = "/opt/gitlab/bin/gitlab-rails runner -e production \'app=Doorkeeper::Application.where(redirect_uri: \"#{gitlab_external_url}\", name: \"GitLab CI\").first_or_create ; puts app.uid.concat(\" \").concat(app.secret);\'"
      o = Mixlib::ShellOut.new(cmd)
      o.run_command

      app_id, app_secret = nil
      if o.exitstatus == 0
        app_id, app_secret = o.stdout.chomp.split(" ")
        gitlab_server = { app_id: app_id, app_secret: app_secret }
        File.open(credentials_file, 'w') { |file| file.write gitlab_server.to_yaml }
        Chef::Log.debug("Created the CI credentials file at #{credentials_file}")
      else
        Chef::Log.warn("Something went wrong while trying to create #{credentials_file}. Check the file permissions and try reconfiguring again.")
      end
    end

    { 'url' => gitlab_external_url, 'app_id' => app_id, 'app_secret' => app_secret }
  end

end

module SingleQuoteHelper

  def single_quote(string)
   "'#{string}'" unless string.nil?
  end

end
