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

require_relative 'postgresql.rb'
require_relative 'redis.rb'

module Prometheus
  class << self
    def services
      %w(
        prometheus
        node-exporter
        redis-exporter
        postgres-exporter
        gitlab-monitor
      )
    end

    def parse_variables
      parse_exporter_enabled
      parse_flags
    end

    def parse_exporter_enabled
      # Disable exporters by default if their service is not managed on this node
      Gitlab['postgres_exporter']['enable'] ||= Postgresql.postgresql_managed?
      Gitlab['redis_exporter']['enable'] ||= Redis.redis_managed?
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
      listen_address = user_config['listen_address'] || default_config['listen_address']
      chunk_encoding_version = user_config['chunk_encoding_version'] || default_config['chunk_encoding_version']
      memory_chunks = user_config['memory_chunks'] || default_config['memory_chunks']
      max_chunks_to_persist = user_config['max_chunks_to_persist'] || default_config['max_chunks_to_persist']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'storage.local.path' => File.join(home_directory, 'data'),
        'storage.local.chunk-encoding-version' => chunk_encoding_version.to_s,
        'storage.local.memory-chunks' => memory_chunks.to_s,
        'storage.local.max-chunks-to-persist' => max_chunks_to_persist.to_s,
        'config.file' => File.join(home_directory, 'prometheus.yml')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['prometheus']['flags'] = default_config['flags']
    end

    def parse_node_exporter_flags
      default_config = Gitlab['node']['gitlab']['node-exporter'].to_hash
      user_config = Gitlab['node_exporter']

      home_directory = user_config['home'] || default_config['home']
      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'collector.textfile.directory' => File.join(home_directory, 'textfile_collector')
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['node_exporter']['flags'] = default_config['flags']
    end

    def parse_redis_exporter_flags
      default_config = Gitlab['node']['gitlab']['redis-exporter'].to_hash
      user_config = Gitlab['redis_exporter']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
        'redis.addr' => "unix://#{Gitlab['node']['gitlab']['gitlab-rails']['redis_socket']}"
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['redis_exporter']['flags'] = default_config['flags']
    end

    def parse_postgres_exporter_flags
      default_config = Gitlab['node']['gitlab']['postgres-exporter'].to_hash
      user_config = Gitlab['postgres_exporter']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      default_config['flags'] = {
        'web.listen-address' => listen_address,
      }

      default_config['flags'].merge!(user_config['flags']) if user_config.key?('flags')

      Gitlab['postgres_exporter']['flags'] = default_config['flags']
    end
  end
end
