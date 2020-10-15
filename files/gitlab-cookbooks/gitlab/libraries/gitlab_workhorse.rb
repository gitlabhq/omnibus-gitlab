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

module GitlabWorkhorse
  class << self
    def parse_variables
      Gitlab['gitlab_workhorse']['auth_socket'] = nil if !auth_socket_specified? && auth_backend_specified?

      user_listen_addr = Gitlab['gitlab_workhorse']['listen_addr']
      Gitlab['gitlab_workhorse']['sockets_directory'] ||= '/var/opt/gitlab/gitlab-workhorse/sockets' unless user_listen_addr.nil?

      sockets_dir = Gitlab['gitlab_workhorse']['sockets_directory']

      default_network = Gitlab['node']['gitlab']['gitlab-workhorse']['listen_network']
      user_network = Gitlab['gitlab_workhorse']['listen_network']
      network = user_network || default_network

      Gitlab['gitlab_workhorse']['listen_addr'] ||= File.join(sockets_dir, 'socket') if network == "unix"
    end

    def parse_secrets
      # gitlab-workhorse expects exactly 32 bytes, encoded with base64
      Gitlab['gitlab_workhorse']['secret_token'] ||= SecureRandom.base64(32)
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
