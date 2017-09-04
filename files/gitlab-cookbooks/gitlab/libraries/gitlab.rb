#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2016 GitLab Inc.
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
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'
require 'uri'

require_relative 'gitlab_mattermost.rb'
require_relative 'gitlab_pages.rb'
require_relative 'gitlab_rails.rb'
require_relative 'gitlab_workhorse.rb'
require_relative 'incoming_email.rb'
require_relative 'logging.rb'
require_relative 'nginx.rb'
require_relative 'postgresql.rb'
require_relative 'redis.rb'
require_relative 'registry.rb'
require_relative 'unicorn.rb'
require_relative 'gitaly.rb'
require_relative 'prometheus.rb'

module Gitlab
  extend(Mixlib::Config)

  bootstrap ConfigMash.new
  omnibus_gitconfig ConfigMash.new
  manage_accounts ConfigMash.new
  manage_storage_directories ConfigMash.new
  runtime_dir nil
  user ConfigMash.new
  postgresql ConfigMash.new
  redis ConfigMash.new
  gitlab_rails ConfigMash.new
  gitlab_ci ConfigMash.new
  gitlab_shell ConfigMash.new
  unicorn ConfigMash.new
  sidekiq ConfigMash.new
  sidekiq_cluster ConfigMash.new
  gitlab_workhorse ConfigMash.new
  gitlab_git_http_server ConfigMash.new # legacy from GitLab 7.14, 8.0, 8.1
  pages_nginx ConfigMash.new
  registry_nginx ConfigMash.new
  mailroom ConfigMash.new
  nginx ConfigMash.new
  mattermost_nginx ConfigMash.new
  logging ConfigMash.new
  remote_syslog ConfigMash.new
  logrotate ConfigMash.new
  high_availability ConfigMash.new
  web_server ConfigMash.new
  mattermost ConfigMash.new
  gitlab_pages ConfigMash.new
  registry ConfigMash.new
  node_exporter ConfigMash.new
  prometheus ConfigMash.new
  redis_exporter ConfigMash.new
  postgres_exporter ConfigMash.new
  gitlab_monitor ConfigMash.new
  sentinel ConfigMash.new
  node nil
  external_url nil
  pages_external_url nil
  mattermost_external_url nil
  registry_external_url nil
  git_data_dirs ConfigMash.new
  gitaly ConfigMash.new
  geo_secondary ConfigMash.new
  geo_postgresql ConfigMash.new
  geo_logcursor ConfigMash.new
  prometheus_monitoring ConfigMash.new
  pgbouncer ConfigMash.new
  repmgr ConfigMash.new
  consul ConfigMash.new

  # Single-Service Roles
  # When enabled, default enabled services are disabled
  redis_sentinel_role ConfigMash.new
  redis_master_role ConfigMash.new
  redis_slave_role ConfigMash.new

  SERVICE_ROLES ||= [
    'redis_sentinel',
    'redis_master',
    'redis_slave',
  ].freeze

  # Behavior roles
  # Used to configure different "defaults" based on intended behavior of the node.
  geo_primary_role ConfigMash.new
  geo_secondary_role ConfigMash.new

  BEHAVIOR_ROLES ||= [
    'geo_primary',
    'geo_secondary',
  ].freeze

  class << self
    def from_file(_file_path)
      # Allow auto mash creation during from_file call
      ConfigMash.auto_vivify { super }
    end

    def method_missing(method_name, *arguments)
      # Give better message for NilClass errors
      # If there are no arguements passed, this is a 'GET' call, and if
      # there is no matching key in the configuration, then it has not been set (not even to nil)
      # and we will output a nicer error above the exception
      if arguments.length == 0 && !configuration.has_key?(method_name)
        message = "Encountered unsupported config key '#{method_name}' in /etc/gitlab/gitlab.rb."
        puts "\n  *ERROR*: #{message}\n"
        Chef::Log.error(message)
      end

      # Parent method_missing takes care of setting values for missing methods
      super
    end

    # guards against creating secrets on non-bootstrap node
    def generate_secrets(node_name)
      SecretsHelper.read_gitlab_secrets

      # Blow up when the existing configuration is ambiguous, so we don't accidentally throw away important secrets
      ci_db_key_base = Gitlab['gitlab_ci']['db_key_base']
      rails_db_key_base = Gitlab['gitlab_rails']['db_key_base']

      if ci_db_key_base && rails_db_key_base && ci_db_key_base != rails_db_key_base
        message = [
          "The value of Gitlab['gitlab_ci']['db_key_base'] (#{ci_db_key_base}) does not match the value of Gitlab['gitlab_rails']['db_key_base'] (#{rails_db_key_base}).",
          "Please back up both secrets, set Gitlab['gitlab_rails']['db_key_base'] to the value of Gitlab['gitlab_ci']['db_key_base'], and try again.",
          "For more information, see <https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update/README.md#migrating-legacy-secrets>"
        ]

        raise message.join("\n\n")
      end

      # Transform legacy key names to new key names
      Gitlab['gitlab_rails']['db_key_base'] ||= Gitlab['gitlab_ci']['db_key_base'] # Changed in 8.11
      Gitlab['gitlab_rails']['secret_key_base'] ||= Gitlab['gitlab_ci']['db_key_base'] # Changed in 8.11
      Gitlab['gitlab_rails']['otp_key_base'] ||= Gitlab['gitlab_rails']['secret_token']

      # Note: If you add another secret to generate here make sure it gets written to disk in SecretsHelper.write_to_gitlab_secrets
      Gitlab['gitlab_rails']['db_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['secret_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['otp_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['jws_private_key'] ||= SecretsHelper.generate_rsa(4096).to_pem

      Gitlab['gitlab_shell']['secret_token'] ||= SecretsHelper.generate_hex(64)

      # gitlab-workhorse expects exactly 32 bytes, encoded with base64
      Gitlab['gitlab_workhorse']['secret_token'] ||= SecureRandom.base64(32)

      Gitlab['registry']['http_secret'] ||= SecretsHelper.generate_hex(64)
      gitlab_registry_crt, gitlab_registry_key = Registry.generate_registry_keypair
      Gitlab['registry']['internal_certificate'] ||= gitlab_registry_crt
      Gitlab['registry']['internal_key'] ||= gitlab_registry_key

      Gitlab['mattermost']['email_invite_salt'] ||= SecretsHelper.generate_hex(16)
      Gitlab['mattermost']['file_public_link_salt'] ||= SecretsHelper.generate_hex(16)
      Gitlab['mattermost']['sql_at_rest_encrypt_key'] ||= SecretsHelper.generate_hex(16)

      SecretsHelper.write_to_gitlab_secrets
    end

    def generate_hash
      # NOTE: If you are adding a new service
      # and that service has logging, make sure you add the service to
      # the array in parse_udp_log_shipping.
      results = { "gitlab" => {} }
      [
        "bootstrap",
        "omnibus_gitconfig",
        "manage_accounts",
        "manage_storage_directories",
        "runtime_dir",
        "user",
        "redis",
        "gitlab_rails",
        "gitlab_ci",
        "gitlab_shell",
        "unicorn",
        "sidekiq",
        "sidekiq-cluster",
        "gitlab_workhorse",
        "mailroom",
        "nginx",
        "mattermost_nginx",
        "pages_nginx",
        "registry_nginx",
        "logging",
        "remote_syslog",
        "logrotate",
        "high_availability",
        "postgresql",
        "web_server",
        "mattermost",
        "external_url",
        "mattermost_external_url",
        "pages_external_url",
        "gitlab_pages",
        "gitaly",
        "node_exporter",
        "prometheus",
        "redis_exporter",
        "postgres_exporter",
        "gitlab_monitor",
        'prometheus_monitoring',
        'pgbouncer',
        "sentinel"
      ].each do |key|
        rkey = key.tr('_', '-')
        results['gitlab'][rkey] = Gitlab[key]
      end

      %w(
        consul
        registry
        repmgr
        repmgrd
      ).each do |key|
        rkey = key.tr('_', '-')
        results[rkey] = Gitlab[key]
      end

      results['roles'] = {}
      (BEHAVIOR_ROLES + SERVICE_ROLES).each do |key|
        rkey = key.gsub('_', '-')
        results['roles'][rkey] = Gitlab["#{key}_role"]
      end

      results
    end

    def generate_config(node_name)
      generate_secrets(node_name)
      GitlabWorkhorse.parse_variables
      GitlabShell.parse_variables
      GitlabRails.parse_variables
      Logging.parse_variables
      Redis.parse_variables
      Postgresql.parse_variables
      Unicorn.parse_variables
      IncomingEmail.parse_variables
      GitlabMattermost.parse_variables
      GitlabPages.parse_variables
      Registry.parse_variables
      Prometheus.parse_variables
      # Parse nginx variables last because we want all external_url to be
      # parsed first
      Nginx.parse_variables
      GitlabRails.disable_services
      # The last step is to convert underscores to hyphens in top-level keys
      generate_hash
    end
  end
end
