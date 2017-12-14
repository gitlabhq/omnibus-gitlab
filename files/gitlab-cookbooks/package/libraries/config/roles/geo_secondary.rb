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

module GeoSecondaryRole
  def self.load_role
    return unless Gitlab['geo_secondary_role']['enable']

    Gitlab['gitlab_rails']['geo_secondary_role_enabled'] = true
    Services.enable_group('geo')
    Gitlab['postgresql']['wal_level'] = 'hot_standby'
    Gitlab['postgresql']['max_wal_senders'] ||= 10
    Gitlab['postgresql']['wal_keep_segments'] ||= 10
    Gitlab['postgresql']['hot_standby'] = 'on'
    Gitlab['gitlab_rails']['auto_migrate'] = false

    # running as a secondary requires several additional processes (geo-postgresql, geo-logcursor, etc).
    # allow more memory for them by reducing the number of Unicorn workers.  Each one is minimum
    # 400MB, so free up 1.2GB.  But maintain our 2 worker minimum. #2858
    memory = Gitlab['node']['memory']['total'].to_i - 1258291
    Gitlab['unicorn']['worker_processes'] = Unicorn.workers(memory)
  end
end
