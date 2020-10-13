#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

require_relative '../../package/libraries/helpers/secrets_helper'

module GitlabKas
  class << self
    def parse_variables
      parse_address
    end

    def parse_address
      Gitlab['gitlab_kas']['gitlab_address'] ||= Gitlab['external_url']
    end

    def parse_secrets
      # KAS and GitLab expects exactly 32 bytes, encoded with base64
      Gitlab['gitlab_kas']['api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))

      api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['api_secret_key'])
      raise "gitlab_kas['api_secret_key'] should be exactly 32 bytes" if api_secret_key.length != 32
    end
  end
end
