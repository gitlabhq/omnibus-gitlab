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
      parse_connect_port
      parse_mattermost_postgresql_settings
      parse_wal_keep_size
    end

    def parse_secrets
      gitlab_postgresql_crt, gitlab_postgresql_key = generate_postgresql_keypair
      Gitlab['postgresql']['internal_certificate'] ||= gitlab_postgresql_crt
      Gitlab['postgresql']['internal_key'] ||= gitlab_postgresql_key
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

    def parse_wal_keep_size
      wal_segment_size = 16
      wal_keep_segments = Gitlab['postgresql']['wal_keep_segments'] || Gitlab['node']['postgresql']['wal_keep_segments']
      wal_keep_size = Gitlab['postgresql']['wal_keep_size'] || Gitlab['node']['postgresql']['wal_keep_size']

      Gitlab['postgresql']['wal_keep_size'] = if wal_keep_size.nil?
                                                wal_keep_segments.to_i * wal_segment_size
                                              else
                                                wal_keep_size
                                              end
    end

    def parse_connect_port
      Gitlab['postgresql']['connect_port'] ||= Gitlab['postgresql']['port'] || Gitlab['node']['postgresql']['port']
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
