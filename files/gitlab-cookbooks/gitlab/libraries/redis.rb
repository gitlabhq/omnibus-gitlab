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
require_relative 'redis_uri.rb'
require_relative 'redis_helper.rb'

module Redis
  class << self
    def parse_variables
      parse_redis_settings
      parse_client_output_settings
      parse_rename_commands
    end

    def parse_redis_settings
      if RedisHelper::Checks.is_redis_tcp?
        # The user wants Redis to listen via TCP instead of unix socket.
        Gitlab['redis']['unixsocket'] = false

        # Try to discover gitlab_rails redis connection params
        # based on redis daemon
        parse_redis_daemon! unless RedisHelper::Checks.has_sentinels?
      end

      Gitlab['redis']['master'] = false if RedisHelper::Checks.replica_role?

      # When announce-ip is defined and announce-port not, infer the later from the main redis_port
      # This functionality makes sense for redis replicas but with sentinel, the redis role can swap
      # We introduce the option regardless the user defined de redis node as master or replica
      Gitlab['redis']['announce_port'] ||= Gitlab['redis']['port'] if Gitlab['redis']['announce_ip']

      Gitlab['redis']['master_password'] ||= Gitlab['redis']['password'] if redis_managed? && (RedisHelper::Checks.sentinel_daemon_enabled? || RedisHelper::Checks.is_redis_replica? || Gitlab['redis_master_role']['enable'])

      return unless RedisHelper::Checks.sentinel_daemon_enabled? || RedisHelper::Checks.is_redis_replica?

      raise "redis 'master_ip' is not defined" unless Gitlab['redis']['master_ip']
      raise "redis 'master_password' is not defined" unless Gitlab['redis']['master_password']
    end

    def parse_client_output_settings
      Gitlab['redis']['client_output_buffer_limit_replica'] ||= Gitlab['redis']['client_output_buffer_limit_slave']

      # If this is nil, don't set it here, as it will override the default
      Gitlab['redis'].delete('client_output_buffer_limit_replica') if Gitlab['redis']['client_output_buffer_limit_replica'].nil?
    end

    def parse_rename_commands
      return unless Gitlab['redis']['rename_commands'].nil?

      Gitlab['redis']['rename_commands'] = {
        'KEYS' => ''
      }
    end

    def redis_managed?
      Services.enabled?('redis')
    end

    private

    def parse_redis_daemon!
      return unless redis_managed?

      redis_bind = Gitlab['redis']['bind'] || node['redis']['bind']

      Gitlab['gitlab_rails']['redis_host'] ||= redis_bind
      Gitlab['gitlab_rails']['redis_port'] ||= Gitlab['redis']['port']
      Gitlab['gitlab_rails']['redis_password'] ||= Gitlab['redis']['master_password']

      Chef::Log.warn "gitlab-rails 'redis_host' is different than 'bind' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_host'] != redis_bind

      Chef::Log.warn "gitlab-rails 'redis_port' is different than 'port' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_port'] != Gitlab['redis']['port']

      Chef::Log.warn "gitlab-rails 'redis_password' is different than 'master_password' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_password'] != Gitlab['redis']['master_password']
    end

    def node
      Gitlab[:node]
    end
  end
end
