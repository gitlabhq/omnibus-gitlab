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

module Grafana
  class << self
    def parse_secrets
      Gitlab['grafana']['secret_key'] ||= SecretsHelper.generate_hex(16)
      Gitlab['grafana']['admin_password'] ||= SecretsHelper.generate_hex(16)

      Gitlab['grafana']['metrics_basic_auth_password'] ||= SecretsHelper.generate_hex(16) if Gitlab['grafana']['metrics_enabled']
    end

    def parse_variables
      parse_grafana_datasources
    end

    def parse_grafana_datasources
      user_config = Gitlab['grafana']
      prom_default_config = Gitlab['node']['monitoring']['prometheus'].to_hash
      prom_user_config = Gitlab['prometheus']

      prom_host = prom_user_config['listen_address'] || prom_default_config['listen_address']
      default_datasources = [
        {
          'name' => 'GitLab Omnibus',
          'type' => 'prometheus',
          'access' => 'proxy',
          'url' => "http://#{prom_host}",
          'isDefault' => true,
        }
      ]

      datasources = user_config['datasources'] || default_datasources

      Gitlab['grafana']['datasources'] = datasources
    end
  end
end
