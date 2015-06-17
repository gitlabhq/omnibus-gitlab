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
  omnibus_gitconfig Mash.new
  user Mash.new
  postgresql Mash.new
  redis Mash.new
  ci_redis Mash.new
  gitlab_rails Mash.new
  gitlab_ci Mash.new
  gitlab_shell Mash.new
  unicorn Mash.new
  ci_unicorn Mash.new
  sidekiq Mash.new
  ci_sidekiq Mash.new
  nginx Mash.new
  ci_nginx Mash.new
  logging Mash.new
  remote_syslog Mash.new
  logrotate Mash.new
  high_availability Mash.new
  web_server Mash.new
  node nil
  external_url nil
  ci_external_url nil
  git_data_dir nil

  class << self

    # guards against creating secrets on non-bootstrap node
    def generate_hex(chars)
      SecureRandom.hex(chars)
    end

    def generate_secrets(node_name)
      SecretsHelper.read_gitlab_secrets

      # Note: If you add another secret to generate here make sure it gets written to disk in SecretsHelper.write_to_gitlab_secrets
      Gitlab['gitlab_shell']['secret_token'] ||= generate_hex(64)
      Gitlab['gitlab_rails']['secret_token'] ||= generate_hex(64)
      Gitlab['gitlab_ci']['secret_token'] ||= generate_hex(64)

      # Note: Besides the section below, gitlab-secrets.json will also change
      # in CiHelper in libraries/helper.rb
      SecretsHelper.write_to_gitlab_secrets
    end

    def parse_external_url
      return unless external_url

      uri = URI(external_url.to_s)

      unless uri.host
        raise "GitLab external URL must include a schema and FQDN, e.g. http://gitlab.example.com/"
      end

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

    def parse_udp_log_shipping
      return unless logging['udp_log_shipping_host']

      Gitlab['remote_syslog']['enable'] ||= true
      Gitlab['remote_syslog']['destination_host'] ||= logging['udp_log_shipping_host']

      if logging['udp_log_shipping_port']
        Gitlab['remote_syslog']['destination_port'] ||= logging['udp_log_shipping_port']
        Gitlab['logging']['svlogd_udp'] ||= "#{logging['udp_log_shipping_host']}:#{logging['udp_log_shipping_port']}"
      else
        Gitlab['logging']['svlogd_udp'] ||= logging['udp_log_shipping_host']
      end

      %w{redis ci-redis nginx sidekiq ci-sidekiq unicorn ci-unicorn postgresql remote-syslog}.each do |runit_sv|
        Gitlab[runit_sv.gsub('-', '_')]['svlogd_prefix'] ||= "#{node['hostname']} #{runit_sv}: "
      end
    end

    def parse_redis_settings
      if gitlab_rails['redis_host']
        # The user wants to connect to a non-bundled Redis instance via TCP.
        # Override the gitlab-rails default redis_port value (nil) to signal
        # that gitlab-rails should connect to Redis via TCP instead of a Unix
        # domain socket.
        Gitlab['gitlab_rails']['redis_port'] ||= 6379
      end

      if gitlab_ci['redis_host']
        Gitlab['gitlab_ci']['redis_port'] ||= 6379
      end

      if gitlab_rails['redis_host'] &&
        gitlab_rails.values_at('redis_host', 'redis_port') == gitlab_ci.values_at('redis_host', 'redis_port')
        Chef::Log.warn "gitlab-rails and gitlab-ci are configured to connect to "\
                       "the same Redis instance. This is not recommended."
      end
    end

    def parse_postgresql_settings
      # If the user wants to run the internal Postgres service using an alternative
      # DB username, host or port, then those settings should also be applied to
      # gitlab-rails and gitlab-ci.
      [
        # %w{gitlab_rails db_username} corresponds to
        # Gitlab['gitlab_rails']['db_username'], etc.
        [%w{gitlab_rails db_username}, %w{postgresql sql_user}],
        [%w{gitlab_rails db_host}, %w{postgresql listen_address}],
        [%w{gitlab_rails db_port}, %w{postgresql port}],
        [%w{gitlab_ci db_username}, %w{postgresql sql_ci_user}],
        [%w{gitlab_ci db_host}, %w{postgresql listen_address}],
        [%w{gitlab_ci db_port}, %w{postgresql port}],
      ].each do |left, right|
        if ! Gitlab[left.first][left.last].nil?
          # If the user explicitly sets a value for e.g.
          # gitlab_rails['db_port'] in gitlab.rb then we should never override
          # that.
          next
        end

        better_value_from_gitlab_rb = Gitlab[right.first][right.last]
        default_from_attributes = node['gitlab'][right.first.gsub('_', '-')][right.last]
        Gitlab[left.first][left.last] = better_value_from_gitlab_rb || default_from_attributes
      end
    end

    def parse_nginx_listen_address
      return unless nginx['listen_address']

      # The user specified a custom NGINX listen address with the legacy
      # listen_address option. We have to convert it to the new
      # listen_addresses setting.
      nginx['listen_addresses'] = [nginx['listen_address']]
    end

    def parse_nginx_listen_ports
      [
        [%w{nginx listen_port}, %w{gitlab_rails gitlab_port}],
        [%w{ci_nginx listen_port}, %w{gitlab_ci gitlab_ci_port}],

      ].each do |left, right|
        if !Gitlab[left.first][left.last].nil?
          next
        end

        default_set_gitlab_port = node['gitlab'][right.first.gsub('_', '-')][right.last]
        user_set_gitlab_port = Gitlab[right.first][right.last]

        Gitlab[left.first][left.last] = user_set_gitlab_port || default_set_gitlab_port
      end
    end

    def parse_ci_external_url
      return unless ci_external_url
      # Enable gitlab_ci. This setting will be picked up by parse_gitlab_ci
      gitlab_ci['enable'] = true if gitlab_ci['enable'].nil?

      uri = URI(ci_external_url.to_s)

      unless uri.host
        raise "GitLab CI external URL must must include a schema and FQDN, e.g. http://ci.example.com/"
      end
      Gitlab['gitlab_ci']['gitlab_ci_host'] = uri.host
      Gitlab['gitlab_ci']['gitlab_ci_email_from'] ||= "gitlab-ci@#{uri.host}"

      case uri.scheme
      when "http"
        Gitlab['gitlab_ci']['gitlab_ci_https'] = false
      when "https"
        Gitlab['gitlab_ci']['gitlab_ci_https'] = true
        Gitlab['ci_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['ci_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        raise "Unsupported CI external URL path: #{uri.path}"
      end

      Gitlab['gitlab_ci']['gitlab_ci_port'] = uri.port
    end

    def parse_gitlab_ci
      return unless gitlab_ci['enable']

      ci_unicorn['enable'] = true if ci_unicorn['enable'].nil?
      ci_sidekiq['enable'] = true if ci_sidekiq['enable'].nil?
      ci_redis['enable'] = true if ci_redis['enable'].nil?
      ci_nginx['enable'] = true if ci_nginx['enable'].nil?
    end

    def generate_hash
      results = { "gitlab" => {} }
      [
        "bootstrap",
        "omnibus_gitconfig",
        "user",
        "redis",
        "ci_redis",
        "gitlab_rails",
        "gitlab_ci",
        "gitlab_shell",
        "unicorn",
        "ci_unicorn",
        "sidekiq",
        "ci_sidekiq",
        "nginx",
        "ci_nginx",
        "logging",
        "remote_syslog",
        "logrotate",
        "high_availability",
        "postgresql",
        "web_server",
        "external_url",
        "ci_external_url"
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
      parse_udp_log_shipping
      parse_redis_settings
      parse_postgresql_settings
      # Parse ci_external_url _before_ gitlab_ci settings so that the user
      # can turn on gitlab_ci by only specifying ci_external_url
      parse_ci_external_url
      parse_nginx_listen_address
      parse_nginx_listen_ports
      parse_gitlab_ci
      # The last step is to convert underscores to hyphens in top-level keys
      generate_hash
    end
  end
end
