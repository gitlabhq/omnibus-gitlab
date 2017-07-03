#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

module Gitaly
  class << self
    def gitaly_address
      socket_path = user_config['socket_path'] || package_default['socket_path']
      listen_addr = user_config['listen_addr'] || package_default['listen_addr']

      # Default to using socket path if available
      if socket_path && !socket_path.empty?
        "unix:#{socket_path}"
      elsif listen_addr && !listen_addr.empty?
        "tcp://#{listen_addr}"
      else
        nil
      end
    end

    private

    def user_config
      Gitlab['gitaly']
    end

    def package_default
      Gitlab['node']['gitlab']['gitaly'].to_hash
    end
  end
end
