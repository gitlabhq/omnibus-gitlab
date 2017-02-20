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

module Prometheus
  class << self
    def parse_variables
      parse_flags
    end

    def parse_flags
      parse_prometheus_flags
      parse_node_exporter_flags
      parse_postgres_exporter_flags
      parse_redis_exporter_flags
    end

    def parse_prometheus_flags
      default_config = Gitlab['node']['gitlab']['prometheus'].to_hash
      user_config = Gitlab['prometheus']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] ||  default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'storage.local.path' => File.join(home_directory, 'data'),
        'storage.local.memory-chunks' => '50000',
        'storage.local.max-chunks-to-persist' => '40000',
        'config.file' => File.join(home_directory, 'prometheus.yml')
      }

      if user_config.keys.include?('flags')
        default_config['flags'].merge!(user_config['flags'])
      end

      Gitlab['prometheus']['flags'] = default_config['flags']
    end

    def parse_node_exporter_flags
      default_config = Gitlab['node']['gitlab']['node-exporter'].to_hash
      user_config = Gitlab['node_exporter']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] ||  default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'collector.textfile.directory' => File.join(home_directory, 'textfile_collector')
      }

      if user_config.keys.include?('flags')
        default_config['flags'].merge!(user_config['flags'])
      end

      Gitlab['node_exporter']['flags'] = default_config['flags']
    end

    def parse_redis_exporter_flags
      default_config = Gitlab['node']['gitlab']['redis-exporter'].to_hash
      user_config = Gitlab['redis_exporter']

      listen_address = user_config['listen_address'] ||  default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'redis.addr' => "unix://#{Gitlab['node']['gitlab']['gitlab-rails']['redis_socket']}"
      }

      if user_config.keys.include?('flags')
        default_config['flags'].merge!(user_config['flags'])
      end

      Gitlab['redis_exporter']['flags'] = default_config['flags']
    end

    def parse_postgres_exporter_flags
      default_config = Gitlab['node']['gitlab']['postgres-exporter'].to_hash
      user_config = Gitlab['postgres_exporter']

      listen_address = user_config['listen_address'] ||  default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
      }

      if user_config.keys.include?('flags')
        default_config['flags'].merge!(user_config['flags'])
      end

      Gitlab['postgres_exporter']['flags'] = default_config['flags']
    end
  end
end
