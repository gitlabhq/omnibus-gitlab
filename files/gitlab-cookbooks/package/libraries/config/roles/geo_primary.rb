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

module GeoPrimaryRole
  def self.load_role
    return unless Gitlab['geo_primary_role']['enable']

    Gitlab['postgresql']['sql_replication_user'] ||= 'gitlab_replicator'
    Gitlab['postgresql']['wal_level'] ||= 'hot_standby'
    Gitlab['postgresql']['max_wal_senders'] ||= 10
    Gitlab['postgresql']['wal_keep_segments'] ||= 50
    Gitlab['postgresql']['max_replication_slots'] ||= 1
    Gitlab['postgresql']['hot_standby'] ||= 'on'
  end
end
