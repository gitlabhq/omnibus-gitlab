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
      if Gitlab['gitlab_rails']['redis_host']
        # The user wants to connect to a non-bundled Redis instance via TCP.
        # Override the gitlab-rails default redis_port value (nil) to signal
        # that gitlab-rails should connect to Redis via TCP instead of a Unix
        # domain socket.
        Gitlab['gitlab_rails']['redis_port'] ||= 6379
      end

      if Gitlab['gitlab_ci']['redis_host']
        Gitlab['gitlab_ci']['redis_port'] ||= 6379
      end

      if Gitlab['gitlab_rails']['redis_host'] &&
        Gitlab['gitlab_rails'].values_at('redis_host', 'redis_port') == Gitlab['gitlab_ci'].values_at('redis_host', 'redis_port')
        Chef::Log.warn "gitlab-rails and gitlab-ci are configured to connect to "\
                       "the same Redis instance. This is not recommended."
      end

      # Redis daemon
      if Gitlab['redis']['bind'] && Gitlab['redis']['port'] != 0
        Chef::Log.debug 'Ignoring redis unixsocket: '\
                        "'#{Gitlab['redis']['unixsocket']}' to use TCP instead"

        # The user wants Redis to listen via TCP instead of unix socket.
        Gitlab['redis']['unixsocket'] = false
      end
    end

    def redis_url
      if Gitlab['redis']['unixsocket']
        uri = URI('unix:/')
        uri.path = Gitlab['redis']['unixsocket']
      else
        uri = URI.parse('redis:/')
        uri.host = Gitlab['gitlab_rails']['redis_host']
        uri.port = Gitlab['gitlab_rails']['redis_port']
        uri.password = Gitlab['gitlab_rails']['redis_password']
        uri.path = "/#{Gitlab['gitlab_rails']['redis_database']}"
      end

      uri
    end
  end
end

