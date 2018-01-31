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
require_relative '../../gitaly/libraries/gitaly.rb'

module GitlabShell
  class << self
    def parse_variables
      parse_auth_file
    end

    def parse_secrets
      Gitlab['gitlab_shell']['secret_token'] ||= SecretsHelper.generate_hex(64)
    end

    def parse_auth_file
      Gitlab['user']['home'] ||= Gitlab['node']['gitlab']['user']['home']
      Gitlab['gitlab_shell']['auth_file'] ||= File.join(Gitlab['user']['home'], '.ssh', 'authorized_keys')
    end
  end
end
