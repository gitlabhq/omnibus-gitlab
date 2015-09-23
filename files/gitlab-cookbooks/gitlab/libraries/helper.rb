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
require 'uri'

module ShellOutHelper

  def do_shell_out(cmd)
    o = Mixlib::ShellOut.new(cmd)
    o.run_command
    o
  end

  def success?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus == 0
  end

  def failure?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus == 3
  end
end

class PgHelper
  include ShellOutHelper
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
           "-h #{pg_host}",
           "--port #{pg_port}",
           cmd_list.join(" ")].join(" ")
    success?(cmd)
  end

  def pg_user
    node['gitlab']['postgresql']['username']
  end

  def pg_port
    node['gitlab']['postgresql']['port']
  end

  def pg_host
    node['gitlab']['postgresql']['unix_socket_directory']
  end

end

class OmnibusHelper
  extend ShellOutHelper

  def self.should_notify?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name)
  end

  def self.not_listening?(service_name)
    File.exists?("/opt/gitlab/service/#{service_name}/down") && service_down?(service_name)
  end

  def self.service_up?(service_name)
    success?("/opt/gitlab/bin/gitlab-ctl status #{service_name}")
  end

  def self.service_down?(service_name)
    failure?("/opt/gitlab/bin/gitlab-ctl status #{service_name}")
  end

  def self.user_exists?(username)
    success?("id -u #{username}")
  end
end

module AuthorizeHelper

  def query_gitlab_rails(uri, name)
    warn("Connecting to GitLab to generate new app_id and app_secret for #{name}.")
    runner_cmd = create_or_find_authorization(uri, name)
    cmd = execute_rails_runner(runner_cmd)
    do_shell_out(cmd)
  end

  def create_or_find_authorization(uri, name)
    args = %Q(redirect_uri: "#{uri}", name: "#{name}")

    app = %Q(app = Doorkeeper::Application.where(#{args}).first_or_create;)

    output = %Q(puts app.uid.concat(" ").concat(app.secret);)

    %W(
      #{app}
      #{output}
    ).join
  end

  def execute_rails_runner(cmd)
    %W(
      /opt/gitlab/bin/gitlab-rails
      runner
      -e production
      '#{cmd}'
    ).join(" ")
  end

  def warn(msg)
    Chef::Log.warn(msg)
  end

  def info(msg)
    Chef::Log.info(msg)
  end
end

class CiHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{Gitlab['ci_external_url']}/user_sessions/callback"
    app_name = "GitLab CI"

    o = query_gitlab_rails(redirect_uri, app_name)

    app_id, app_secret = nil
    if o.exitstatus == 0
      app_id, app_secret = o.stdout.chomp.split(" ")

      Gitlab['gitlab_ci']['gitlab_server'] = { 'url' => gitlab_external_url,
                                                 'app_id' => app_id,
                                                 'app_secret' => app_secret
                                               }

      SecretsHelper.write_to_gitlab_secrets
      info("Updated the gitlab-secrets.json file.")
    else
      warn("Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.")
    end

    { 'url' => gitlab_external_url, 'app_id' => app_id, 'app_secret' => app_secret }
  end

  def self.gitlab_server
    return unless Gitlab['gitlab_ci']['gitlab_server']
    Gitlab['gitlab_ci']['gitlab_server']
  end

  def self.gitlab_server_fqdn
    if gitlab_server && gitlab_server['url']
      uri = URI(gitlab_server['url'].to_s)
      uri.host
    else
      Gitlab['gitlab_rails']['gitlab_host']
    end
  end
end

class MattermostHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{Gitlab['mattermost_external_url']}/signup/gitlab/complete\r\n#{Gitlab['mattermost_external_url']}/login/gitlab/complete"
    app_name = "GitLab Mattermost"

    o = query_gitlab_rails(redirect_uri, app_name)

    app_id, app_secret = nil
    if o.exitstatus == 0
      app_id, app_secret = o.stdout.chomp.split(" ")
      gitlab_url = gitlab_external_url.chomp("/")

      Gitlab['mattermost']['oauth'] = {} unless Gitlab['mattermost']['oauth']
      Gitlab['mattermost']['oauth']['gitlab'] = { 'Allow' => true,
                                                  'Secret' => app_secret,
                                                  'Id' => app_id,
                                                  'AuthEndpoint' => "#{gitlab_url}/oauth/authorize",
                                                  'TokenEndpoint' => "#{gitlab_url}/oauth/token",
                                                  'UserApiEndpoint' => "#{gitlab_url}/api/v3/user",
                                                  'Scope' => ""
                                                }

      SecretsHelper.write_to_gitlab_secrets
      info("Updated the gitlab-secrets.json file.")
    else
      warn("Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.")
    end

    { 'Allow' => true,
      'Secret' => app_secret,
      'Id' => app_id,
      'AuthEndpoint' => "#{gitlab_url}/oauth/authorize",
      'TokenEndpoint' => "#{gitlab_url}/oauth/token",
      'UserApiEndpoint' => "#{gitlab_url}/api/v3/user",
      'Scope' => ""
     }
  end
end

class SecretsHelper

  def self.read_gitlab_secrets
    existing_secrets ||= Hash.new

    if File.exists?("/etc/gitlab/gitlab-secrets.json")
      existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json"))
    end

    existing_secrets.each do |k, v|
      if Gitlab[k]
        v.each do |pk, p|
          # Note: Specifiying a secret in gitlab.rb will take precendence over "gitlab-secrets.json"
          Gitlab[k][pk] ||= p
        end
      else
        warn("Ignoring section #{k} in /etc/gitlab/giltab-secrets.json, does not exist in gitlab.rb")
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
                        'secret_key_base' => Gitlab['gitlab_ci']['secret_key_base'],
                        'db_key_base' => Gitlab['gitlab_ci']['db_key_base'],
                      },
                      'mattermost' => {
                        'service_invite_salt' => Gitlab['mattermost']['service_invite_salt'],
                        'service_public_link_salt' => Gitlab['mattermost']['service_public_link_salt'],
                        'service_reset_salt' => Gitlab['mattermost']['service_reset_salt'],
                        'sql_at_rest_encrypt_key' => Gitlab['mattermost']['sql_at_rest_encrypt_key']
                      }
                    }

    if Gitlab['gitlab_ci']['gitlab_server']
      ci_auth = {
                  'gitlab_server' => {
                    'url' => Gitlab['gitlab_ci']['gitlab_server']['url'],
                    'app_id' => Gitlab['gitlab_ci']['gitlab_server']['app_id'],
                    'app_secret' => Gitlab['gitlab_ci']['gitlab_server']['app_secret']
                  }
                }
      secret_tokens['gitlab_ci'].merge!(ci_auth)
    end

    if Gitlab['mattermost']['oauth'] && Gitlab['mattermost']['oauth']['gitlab']
      gitlab_oauth = { 'oauth' =>
                        {
                          'gitlab' => Gitlab['mattermost']['oauth']['gitlab']
                        }
                     }
      secret_tokens['mattermost'].merge!(gitlab_oauth)
    end

    if File.directory?("/etc/gitlab")
      File.open("/etc/gitlab/gitlab-secrets.json", "w") do |f|
        f.puts(
          Chef::JSONCompat.to_json_pretty(secret_tokens)
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

class RedhatHelper

  def self.system_is_rhel7?
    platform_family == "rhel" && platform_version =~ /7\./
  end

  def self.platform_family
    case platform
    when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/
      "rhel"
    else
      "not redhat"
    end
  end

  def self.platform
    contents = read_release_file
    get_redhatish_platform(contents)
  end

  def self.platform_version
    contents = read_release_file
    get_redhatish_version(contents)
  end

  def self.read_release_file
    if File.exists?("/etc/redhat-release")
      contents = File.read("/etc/redhat-release").chomp
    else
      "not redhat"
    end
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/31f6415c853f3070b0399ac2eb09094eb81939d2/lib/ohai/plugins/linux/platform.rb#L23
  def self.get_redhatish_platform(contents)
    contents[/^Red Hat/i] ? "redhat" : contents[/(\w+)/i, 1].downcase
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/31f6415c853f3070b0399ac2eb09094eb81939d2/lib/ohai/plugins/linux/platform.rb#L27
  def self.get_redhatish_version(contents)
    contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/release ([\d\.]+)/, 1]
  end
end
