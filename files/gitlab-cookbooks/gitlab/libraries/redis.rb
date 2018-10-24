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
      if is_redis_tcp?
        # The user wants Redis to listen via TCP instead of unix socket.
        Gitlab['redis']['unixsocket'] = false

        # Try to discover gitlab_rails redis connection params
        # based on redis daemon
        parse_redis_daemon! unless has_sentinels?
      end

      Gitlab['redis']['master'] = false if Gitlab['redis_slave_role']['enable']

      # When announce-ip is defined and announce-port not, infer the later from the main redis_port
      # This functionality makes sense for redis slaves but with sentinel, the redis role can swap
      # We introduce the option regardless the user defined de redis node as master or slave
      if Gitlab['redis']['announce_ip']
        Gitlab['redis']['announce_port'] ||= Gitlab['redis']['port']
      end

      if redis_managed? && (sentinel_daemon_enabled? || is_redis_slave? || Gitlab['redis_master_role']['enable'])
        Gitlab['redis']['master_password'] ||= Gitlab['redis']['password']
      end

      if sentinel_daemon_enabled? || is_redis_slave?
        raise "redis 'master_ip' is not defined" unless Gitlab['redis']['master_ip']
        raise "redis 'master_password' is not defined" unless Gitlab['redis']['master_password']
      end

      # Try to discover gitlab_rails redis connection params
      # based on sentinels node data
      parse_sentinels! if has_sentinels?

      return unless is_gitlab_rails_redis_tcp?

      # The user wants to connect to a Redis instance via TCP.
      # It can be either a non-bundled instance or a Sentinel based one.
      # Overriding redis_socket to false signals that gitlab-rails
      # should connect to Redis via TCP instead of a Unix domain socket.
      Gitlab['gitlab_rails']['redis_port'] ||= 6379
      Gitlab['gitlab_rails']['redis_socket'] = false
    end

    def redis_managed?
      Services.enabled?('redis')
    end

    private

    # Parses sentinel specific meta-data to fill gitlab_rails
    #
    # Redis sentinel requires the url to point to the 'master_name' instead of
    # an IP or a valid host. We also need to ignore port and make sure we use
    # correct password
    def parse_sentinels!
      master_name = Gitlab['redis']['master_name'] || node['redis']['master_name']

      if Gitlab['gitlab_rails']['redis_host'] != master_name
        Gitlab['gitlab_rails']['redis_host'] = master_name

        Chef::Log.warn "gitlab-rails 'redis_host' will be ignored as sentinel is defined."
      end

      if Gitlab['gitlab_rails']['redis_port']
        Gitlab['gitlab_rails']['redis_port'] = nil

        Chef::Log.warn "gitlab-rails 'redis_port' will be ignored as sentinel is defined."
      end

      return unless Gitlab['gitlab_rails']['redis_password'] != Gitlab['redis']['master_password']

      Gitlab['gitlab_rails']['redis_password'] = Gitlab['redis']['master_password']
      Chef::Log.warn "gitlab-rails 'redis_password' will be ignored as sentinel is defined."
    end

    def parse_redis_daemon!
      return unless redis_managed?
      redis_bind = Gitlab['redis']['bind'] || node['redis']['bind']

      Gitlab['gitlab_rails']['redis_host'] ||= redis_bind
      Gitlab['gitlab_rails']['redis_port'] ||= Gitlab['redis']['port']
      Gitlab['gitlab_rails']['redis_password'] ||= Gitlab['redis']['master_password']

      if Gitlab['gitlab_rails']['redis_host'] != redis_bind
        Chef::Log.warn "gitlab-rails 'redis_host' is different than 'bind' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?"
      end

      if Gitlab['gitlab_rails']['redis_port'] != Gitlab['redis']['port']
        Chef::Log.warn "gitlab-rails 'redis_port' is different than 'port' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?"
      end

      Chef::Log.warn "gitlab-rails 'redis_password' is different than 'master_password' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_password'] != Gitlab['redis']['master_password']
    end

    def node
      Gitlab[:node]
    end

    def is_redis_tcp?
      Gitlab['redis']['port'] && Gitlab['redis']['port'].positive?
    end

    def is_redis_slave?
      Gitlab['redis']['master'] == false
    end

    def sentinel_daemon_enabled?
      Services.enabled?('sentinel')
    end

    def is_gitlab_rails_redis_tcp?
      Gitlab['gitlab_rails']['redis_host']
    end

    def has_sentinels?
      Gitlab['gitlab_rails']['redis_sentinels'] && !Gitlab['gitlab_rails']['redis_sentinels'].empty?
    end
  end
end
