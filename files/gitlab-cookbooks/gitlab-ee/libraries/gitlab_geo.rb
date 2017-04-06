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

module GitlabGeo
  class << self
    def parse_variables
      parse_primary_role if geo_primary_role?
      parse_secondary_role if geo_secondary_role?
      parse_data_dir if geo_postgresql_enabled?
    end

    private

    def parse_primary_role
      Gitlab['postgresql']['sql_replication_user'] ||= 'gitlab_replicator'
      Gitlab['postgresql']['wal_level'] = 'hot_standby'
      Gitlab['postgresql']['max_wal_senders'] ||= 10
      Gitlab['postgresql']['wal_keep_segments'] ||= 10
      Gitlab['postgresql']['hot_standby'] = 'on'
    end

    def parse_secondary_role
      Gitlab['geo_postgresql']['enable'] = true
      Gitlab['postgresql']['wal_level'] = 'hot_standby'
      Gitlab['postgresql']['max_wal_senders'] ||= 10
      Gitlab['postgresql']['wal_keep_segments'] ||= 10
      Gitlab['postgresql']['hot_standby'] = 'on'
      Gitlab['gitlab_rails']['auto_migrate'] = false
    end

    def parse_data_dir
      postgresql_data_dir = Gitlab['geo_postgresql']['data_dir'] || node['gitlab']['geo-postgresql']['data_dir']
      Gitlab['geo_postgresql']['bootstrap'] = !File.exists?(File.join(postgresql_data_dir, 'PG_VERSION'))
    end

    def geo_primary_role?
      Gitlab['geo_primary_role']['enable']
    end

    def geo_secondary_role?
      Gitlab['geo_secondary_role']['enable']
    end

    def geo_postgresql_enabled?
      Gitlab['geo_postgresql']['enable']
    end

    def node
      Gitlab[:node]
    end
  end
end
