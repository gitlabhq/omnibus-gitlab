#
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

module Postgresql
  class << self
    def parse_variables
      parse_postgresql_settings
      parse_multi_db_host_addresses
      parse_mattermost_postgresql_settings
    end

    def parse_secrets
      gitlab_postgresql_crt, gitlab_postgresql_key = generate_postgresql_keypair
      Gitlab['postgresql']['internal_certificate'] ||= gitlab_postgresql_crt
      Gitlab['postgresql']['internal_key'] ||= gitlab_postgresql_key
    end

    def parse_postgresql_settings
      # If the user wants to run the internal Postgres service using an alternative
      # DB username, host or port, then those settings should also be applied to
      # gitlab-rails.
      [
        # %w{gitlab_rails db_username} corresponds to
        # Gitlab['gitlab_rails']['db_username'], etc.
        [%w(gitlab_rails db_username), %w(postgresql sql_user)],
        [%w(gitlab_rails db_host), %w(postgresql listen_address)],
        [%w(gitlab_rails db_port), %w(postgresql port)],
      ].each do |left, right|
        unless Gitlab[left.first][left.last].nil?
          # If the user explicitly sets a value for e.g.
          # gitlab_rails['db_port'] in gitlab.rb then we should never override
          # that.
          next
        end

        better_value_from_gitlab_rb = Gitlab[right.first][right.last]
        default_from_attributes = Gitlab['node']['gitlab'][left.first.tr('_', '-')][left.last]
        Gitlab[left.first][left.last] = better_value_from_gitlab_rb || default_from_attributes
      end
    end

    def parse_multi_db_host_addresses
      # Postgres allow multiple listen addresses, comma-separated values
      # In case of multi listen_address, will use the first address from list
      db_host = Gitlab['gitlab_rails']['db_host']
      return unless db_host&.include?(',')

      Gitlab['gitlab_rails']['db_host'] = db_host.split(',')[0]
      warning = [
        "Received gitlab_rails['db_host'] value was: #{db_host.to_json}.",
        "First listen_address '#{Gitlab['gitlab_rails']['db_host']}' will be used."
      ].join("\n  ")
      warn(warning)
    end

    def parse_mattermost_postgresql_settings
      value_from_gitlab_rb = Gitlab['mattermost']['sql_data_source']

      user = Gitlab['postgresql']['sql_mattermost_user'] || Gitlab['node']['postgresql']['sql_mattermost_user']
      unix_socket_directory = Gitlab['postgresql']['unix_socket_directory'] || Gitlab['node']['postgresql']['unix_socket_directory']
      postgres_directory = Gitlab['postgresql']['dir'] || Gitlab['node']['postgresql']['dir']
      port = Gitlab['postgresql']['port'] || Gitlab['node']['postgresql']['port']
      database_name = Gitlab['mattermost']['database_name'] || Gitlab['node']['mattermost']['database_name']
      host = unix_socket_directory || postgres_directory

      value_from_attributes = "user=#{user} host=#{host} port=#{port} dbname=#{database_name}"
      Gitlab['mattermost']['sql_data_source'] = value_from_gitlab_rb || value_from_attributes
    end

    def postgresql_managed?
      Services.enabled?('postgresql')
    end

    def generate_postgresql_keypair
      key, cert = SecretsHelper.generate_keypair(
        bits: 4096,
        subject: "/C=USA/O=GitLab/OU=Database/CN=PostgreSQL",
        validity: 365 * 10 # ten years from now
      )

      [cert.to_pem, key.to_pem]
    end
  end
end
