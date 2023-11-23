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

require_relative './redis_uri'
require_relative '../../package/libraries/helpers/new_redis_helper'

module GitlabWorkhorse
  class << self
    def parse_variables
      Gitlab['gitlab_workhorse']['auth_socket'] = nil if !auth_socket_specified? && auth_backend_specified?

      user_listen_addr = Gitlab['gitlab_workhorse']['listen_addr']
      Gitlab['gitlab_workhorse']['sockets_directory'] ||= '/var/opt/gitlab/gitlab-workhorse/sockets' if user_listen_addr.nil?

      sockets_dir = Gitlab['gitlab_workhorse']['sockets_directory']

      default_network = Gitlab['node']['gitlab']['gitlab_workhorse']['listen_network']
      user_network = Gitlab['gitlab_workhorse']['listen_network']
      network = user_network || default_network

      Gitlab['gitlab_workhorse']['listen_addr'] ||= File.join(sockets_dir, 'socket') if network == "unix"

      parse_redis_settings
    end

    def parse_secrets
      # gitlab-workhorse expects exactly 32 bytes, encoded with base64
      Gitlab['gitlab_workhorse']['secret_token'] ||= SecureRandom.base64(32)
    end

    def parse_redis_settings
      gitlab_workhorse_redis_configured = Gitlab['gitlab_workhorse'].key?('redis_socket') ||
        Gitlab['gitlab_workhorse'].key?('redis_host')

      rails_workhorse_redis_configured =
        Gitlab['gitlab_rails']['redis_workhorse_instance'] ||
        (Gitlab['gitlab_rails']['redis_workhorse_sentinels'] &&
         !Gitlab['gitlab_rails']['redis_workhorse_sentinels'].empty?)

      if gitlab_workhorse_redis_configured
        # Parse settings from `redis['master_*']` first.
        parse_redis_master_settings
        # If gitlab_workhorse settings are specified, populate
        # gitlab_rails['redis_workhorse_*'] settings from it.
        update_separate_redis_instance_settings
      elsif rails_workhorse_redis_configured
        # If user has specified a separate Redis host for Workhorse via
        # `gitlab_rails['redis_workhorse_*']` settings, copy them to
        # `gitlab_workhorse['redis_*']`.
        parse_separate_redis_instance_settings
        parse_redis_master_settings
      else
        # If user hasn't specified any separate Redis settings for Workhorse,
        # copy the global settings from GitLab Rails
        parse_global_rails_redis_settings
        parse_redis_master_settings
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/PerceivedComplexity
    def update_separate_redis_instance_settings
      if Gitlab['gitlab_workhorse']['redis_host']
        uri_from_workhorse = NewRedisHelper.build_redis_url(
          ssl: Gitlab['gitlab_workhorse']['redis_ssl'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_ssl'],
          host: Gitlab['gitlab_workhorse']['redis_host'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_host'],
          port: Gitlab['gitlab_workhorse']['redis_port'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_port'],
          password: Gitlab['gitlab_workhorse']['redis_password'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_password'],
          path: Gitlab['gitlab_workhorse']['redis_database'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_database']
        ).to_s

        uri_from_rails = NewRedisHelper.build_redis_url(
          ssl: Gitlab['gitlab_rails']['redis_ssl'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_ssl'],
          host: Gitlab['gitlab_rails']['redis_host'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_host'],
          port: Gitlab['gitlab_rails']['redis_port'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_port'],
          password: Gitlab['gitlab_rails']['redis_password'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_password'],
          path: Gitlab['gitlab_rails']['redis_database'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_database']
        ).to_s
        Gitlab['gitlab_rails']['redis_workhorse_instance'] = uri_from_workhorse if uri_from_workhorse != uri_from_rails

      else
        workhorse_redis_socket = Gitlab['gitlab_workhorse']['redis_socket'] || Gitlab['node']['gitlab']['gitlab_workhorse']['redis_socket']
        rails_redis_socket = Gitlab['gitlab_rails']['redis_socket'] || Gitlab['node']['gitlab']['gitlab_rails']['redis_socket']
        Gitlab['gitlab_rails']['redis_workhorse_instance'] = "unix://#{workhorse_redis_socket}" if workhorse_redis_socket != rails_redis_socket
      end

      %w[username password cluster_nodes sentinels sentinel_master sentinels_password].each do |setting|
        Gitlab['gitlab_rails']["redis_workhorse_#{setting}"] ||= Gitlab['gitlab_workhorse']["redis_#{setting}"]
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity

    def parse_global_rails_redis_settings
      %w[ssl host socket port password database sentinels sentinels_password].each do |setting|
        Gitlab['gitlab_workhorse']["redis_#{setting}"] ||= Gitlab['gitlab_rails']["redis_#{setting}"]
      end
    end

    def parse_separate_redis_instance_settings
      # If an individual Redis instance is specified for Workhorse, figure out
      # host, port, password, etc. from it
      if Gitlab['gitlab_rails']['redis_workhorse_instance']
        uri = URI(Gitlab['gitlab_rails']['redis_workhorse_instance'])

        Gitlab['gitlab_workhorse']['redis_ssl'] = uri.scheme == 'rediss' unless Gitlab['gitlab_workhorse'].key?('redis_ssl')
        if uri.scheme == 'unix'
          Gitlab['gitlab_workhorse']['redis_socket'] = uri.path
        else
          Gitlab['gitlab_workhorse']['redis_host'] ||= if uri.path.start_with?('/')
                                                         uri.host
                                                       else
                                                         uri.path
                                                       end
          Gitlab['gitlab_workhorse']['redis_port'] ||= uri.port
          Gitlab['gitlab_workhorse']['redis_password'] ||= uri.password
          Gitlab['gitlab_workhorse']['redis_database'] ||= uri.path.delete_prefix('/') if uri.path.start_with?('/')
        end
      end

      %w[username password cluster_nodes sentinels sentinel_master sentinels_password].each do |setting|
        Gitlab['gitlab_workhorse']["redis_#{setting}"] ||= Gitlab['gitlab_rails']["redis_workhorse_#{setting}"]
      end
    end

    def parse_redis_master_settings
      # TODO: When GitLab rails gets it's own set if `redis_sentinel_master_*`
      # settings, update the following to use them instead of
      # `Gitlab['redis'][*]` settings. It can be then merged with
      # `parse_rails_redis_settings` method
      Gitlab['gitlab_workhorse']['redis_sentinel_master'] ||= Gitlab['redis']['master_name'] || Gitlab[:node]['redis']['master_name']
      Gitlab['gitlab_workhorse']['redis_sentinel_master_ip'] ||= Gitlab['redis']['master_ip'] || Gitlab[:node]['redis']['master_ip']
      Gitlab['gitlab_workhorse']['redis_sentinel_master_port'] ||= Gitlab['redis']['master_port'] || Gitlab[:node]['redis']['master_port']
      Gitlab['gitlab_workhorse']['redis_password'] ||= Gitlab['redis']['master_password'] || Gitlab[:node]['redis']['master_password']
    end

    private

    def auth_socket_specified?
      auth_socket = Gitlab['gitlab_workhorse']['auth_socket']

      !auth_socket&.empty?
    end

    def auth_backend_specified?
      auth_backend = Gitlab['gitlab_workhorse']['auth_backend']

      !auth_backend&.empty?
    end
  end
end
