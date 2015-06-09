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
    credentials_file = "/etc/gitlab/gitlab-secrets.json"

    Chef::Log.warn("Connecting to GitLab to generate new app_id and app_secret.")
    runner_cmd = [
      "app=Doorkeeper::Application.where(redirect_uri: \"#{gitlab_external_url}\", name: \"GitLab CI\").first_or_create",
      "puts app.uid.concat(\" \").concat(app.secret);"
      ].join(" ;")

    cmd = [
      '/opt/gitlab/bin/gitlab-rails',
      'runner',
      '-e production',
      "\'#{runner_cmd}\'"
    ].join(" ")

    o = Mixlib::ShellOut.new(cmd)
    o.run_command

    app_id, app_secret = nil
    if o.exitstatus == 0
      app_id, app_secret = o.stdout.chomp.split(" ")

      Gitlab['gitlab_ci']['gitlab_server'] = { 'url' => gitlab_external_url,
                                                 'app_id' => app_id,
                                                 'app_secret' => app_secret
                                               }

      SecretsHelper.write_to_gitlab_secrets

      Chef::Log.info("Updated the #{credentials_file} file.")
    else
      Chef::Log.warn("Something went wrong while trying to update #{credentials_file}. Check the file permissions (default 600) and try reconfiguring again.")
    end

    { 'url' => gitlab_external_url, 'app_id' => app_id, 'app_secret' => app_secret }
  end

end

class SecretsHelper

  def self.read_gitlab_secrets
    existing_secrets ||= Hash.new

    if File.exists?("/etc/gitlab/gitlab-secrets.json")
      existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json"))
    end

    existing_secrets.each do |k, v|
      v.each do |pk, p|
        # Note: Specifiying a secret in gitlab.rb will take precendence over the `gitlab-secrets.json`
        Gitlab[k][pk] ||= p
      end
    end
  end

  def self.write_to_gitlab_secrets
    secret_tokens = {
                      'gitlab_shell' => {
                        'secret_token' => Gitlab['gitlab_shell']['secret_token'],
                      },
                      'gitlab_rails' => {
                        'secret_token' => Gitlab['gitlab_rails']['secret_token'],
                      },
                      'gitlab_ci' => {
                        'secret_token' => Gitlab['gitlab_ci']['secret_token'],
                      }
                    }

    ci_credentials = if Gitlab['gitlab_ci']['gitlab_server']
       { 'gitlab_ci' => {
                          'secret_token' => Gitlab['gitlab_ci']['secret_token'],
                          'gitlab_server' => {
                            'url' => Gitlab['gitlab_ci']['gitlab_server']['url'],
                            'app_id' => Gitlab['gitlab_ci']['gitlab_server']['app_id'],
                            'app_secret' => Gitlab['gitlab_ci']['gitlab_server']['app_secret']
                          }
                        }
        }
    else
      {}
    end

    if File.directory?("/etc/gitlab")
      File.open("/etc/gitlab/gitlab-secrets.json", "w") do |f|
        f.puts(
          Chef::JSONCompat.to_json_pretty(secret_tokens.merge(ci_credentials))
        )
        system("chmod 0600 /etc/gitlab/gitlab-secrets.json")
      end
    end
  end

end

module SingleQuoteHelper

  def single_quote(string)
   "'#{string}'" unless string.nil?
  end

end
