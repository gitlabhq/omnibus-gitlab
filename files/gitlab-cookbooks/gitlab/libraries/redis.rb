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

module Redis
  class << self
    def parse_variables
      parse_redis_settings
    end

    def parse_redis_settings
      node = Gitlab[:node]['gitlab']

      if is_redis_tcp?
        # The user wants Redis to listen via TCP instead of unix socket.
        Gitlab['redis']['unixsocket'] = false

        # Try to discover gitlab_rails redis connection params
        # based on redis daemon definition or sentinels
        if has_sentinels?
          master_name = Gitlab['redis']['master_name'] || node['redis']['master_name']
          redis_bind = Gitlab['redis']['bind'] || node['redis']['bind']

          # Redis sentinel requires the url to point to the 'master_name' instead of
          # an IP or a valid host. We are also hard-coding port just to keep url clean.
          if Gitlab['gitlab_rails']['redis_host'] != master_name
            Chef::Log.warn "gitlab-rails 'redis_host' will be ignored as sentinel is defined."
          end

          Gitlab['gitlab_rails']['redis_host'] = master_name
          Gitlab['gitlab_rails']['redis_port'] = 6379
        else
          Gitlab['gitlab_rails']['redis_host'] ||= redis_bind
          Gitlab['gitlab_rails']['redis_port'] ||= Gitlab['redis']['port']
        end

        if sentinel_daemon_enabled? || is_redis_slave?
          fail "redis 'master_ip' is not defined" unless Gitlab['redis']['master_ip']
          fail "redis 'master_port' is not defined" unless Gitlab['redis']['master_port']
          fail "redis 'master_password' is not defined" unless Gitlab['redis']['master_password']
        end

        if Gitlab['gitlab_rails']['redis_host'] != redis_bind
          Chef::Log.warn "gitlab-rails 'redis_host' is different than 'bind' value defined for managed redis instance."
        end

        if Gitlab['gitlab_rails']['redis_port'] != Gitlab['redis']['port']
          Chef::Log.warn "gitlab-rails 'redis_port' is different than 'port' value defined for managed redis instance."
        end
      end

      if is_gitlab_rails_redis_tcp?
        # The user wants to connect to a Redis instance via TCP.
        # It can be either a non-bundled instance or a Sentinel based one.
        # Overriding redis_socket to false signals that gitlab-rails
        # should connect to Redis via TCP instead of a Unix domain socket.
        Gitlab['gitlab_rails']['redis_port'] ||= 6379
        Gitlab['gitlab_rails']['redis_socket'] = false
      end
    end

    private

    def is_redis_tcp?
      Gitlab['redis']['port'] && Gitlab['redis']['port'] > 0
    end

    def is_redis_slave?
      Gitlab['redis']['master'] == false
    end

    def sentinel_daemon_enabled?
      Gitlab['sentinel']['enable']
    end

    def is_gitlab_rails_redis_tcp?
      Gitlab['gitlab_rails']['redis_host']
    end

    def has_sentinels?
      Gitlab['gitlab_rails']['redis_sentinels']
    end
  end
end
