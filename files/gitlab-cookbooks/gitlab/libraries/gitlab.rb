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

# The Gitlab module in this file is used to parse /etc/gitlab/gitlab.rb.
#
# Warning to the reader:
# Because the Ruby DSL in /etc/gitlab/gitlab.rb does not accept hyphens in
# section names, this module translates names like 'gitlab_rails' to the
# correct 'gitlab-rails' in the `generate_hash` method. This module is the only
# place in the cookbook where we write 'gitlab_rails'.

require 'mixlib/config'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'
require 'uri'

module Gitlab
  extend(Mixlib::Config)

  bootstrap Mash.new
  user Mash.new
  postgresql Mash.new
  redis Mash.new
  gitlab_rails Mash.new
  gitlab_shell Mash.new
  unicorn Mash.new
  sidekiq Mash.new
  nginx Mash.new
  node nil
  external_url nil
  git_data_dir nil

  class << self

    # guards against creating secrets on non-bootstrap node
    def generate_hex(chars)
      SecureRandom.hex(chars)
    end

    def generate_secrets(node_name)
      existing_secrets ||= Hash.new
      if File.exists?("/etc/gitlab/gitlab-secrets.json")
        existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json"))
      end
      existing_secrets.each do |k, v|
        v.each do |pk, p|
          Gitlab[k][pk] = p
        end
      end

      Gitlab['gitlab_rails']['secret_token'] ||= generate_hex(64)

      if File.directory?("/etc/gitlab")
        File.open("/etc/gitlab/gitlab-secrets.json", "w") do |f|
          f.puts(
            Chef::JSONCompat.to_json_pretty({
              'gitlab_rails' => {
                'secret_token' => Gitlab['gitlab_rails']['secret_token'],
              }
            })
          )
          system("chmod 0600 /etc/gitlab/gitlab-secrets.json")
        end
      end
    end

    def parse_external_url
      return unless external_url

      uri = URI(external_url.to_s)

      unless uri.host
        raise "External URL must include a FQDN"
      end
      Gitlab['user']['git_user_email'] ||= "gitlab@#{uri.host}"
      Gitlab['gitlab_rails']['gitlab_host'] = uri.host
      Gitlab['gitlab_rails']['gitlab_email_from'] ||= "gitlab@#{uri.host}"

      case uri.scheme
      when "http"
        Gitlab['gitlab_rails']['gitlab_https'] = false
      when "https"
        Gitlab['gitlab_rails']['gitlab_https'] = true
        Gitlab['nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        raise "Unsupported external URL path: #{uri.path}"
      end

      Gitlab['gitlab_rails']['gitlab_port'] = uri.port
    end

    def parse_git_data_dir
      return unless git_data_dir

      Gitlab['gitlab_shell']['git_data_directory'] ||= git_data_dir
      Gitlab['gitlab_rails']['gitlab_shell_repos_path'] ||= File.join(git_data_dir, "repositories")
      Gitlab['gitlab_rails']['satellites_path'] ||= File.join(git_data_dir, "gitlab-satellites")
    end

    def generate_hash
      results = { "gitlab" => {} }
      [
        "bootstrap",
        "user",
        "redis",
        "gitlab_rails",
        "gitlab_shell",
        "unicorn",
        "sidekiq",
        "nginx",
        "postgresql"
      ].each do |key|
        rkey = key.gsub('_', '-')
        results['gitlab'][rkey] = Gitlab[key]
      end

      results
    end

    def generate_config(node_name)
      generate_secrets(node_name)
      parse_external_url
      parse_git_data_dir
      # The last step is to convert underscores to hyphens in top-level keys
      generate_hash
    end
  end
end
