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

    Services.enable_group('geo')
    Gitlab['geo_secondary']['enable'] = true if Gitlab['geo_secondary']['enable'].nil?
    Gitlab['postgresql']['wal_level'] ||= 'hot_standby'
    Gitlab['postgresql']['max_wal_senders'] ||= 10
    Gitlab['postgresql']['wal_keep_segments'] ||= 10
    # This helps prevent query conflicts
    Gitlab['postgresql']['max_standby_archive_delay'] ||= '60s'
    Gitlab['postgresql']['max_standby_streaming_delay'] ||= '60s'
    Gitlab['postgresql']['hot_standby'] ||= 'on'
    Gitlab['gitlab_rails']['auto_migrate'] ||= false
    Gitlab['gitlab_rails']['enable'] = rails_needed? if Gitlab['gitlab_rails']['enable'].nil?
    Gitlab[WebServerHelper.service_name]['worker_processes'] ||= number_of_worker_processes
  end

  def self.rails_needed?
    Gitlab['unicorn']['enable'] ||
      Gitlab['puma']['enable'] ||
      Gitlab['sidekiq']['enable'] ||
      Gitlab['sidekiq_cluster']['enable'] ||
      Gitlab['gitaly']['enable'] ||
      Gitlab['geo_logcursor']['enable']
  end

  # running as a secondary requires several additional processes (geo-postgresql, geo-logcursor, etc).
  # allow more memory for them by reducing the number of Unicorn workers.  Each one is minimum
  # 400MB, so free up 1.2GB.  But maintain our 2 worker minimum. #2858
  def self.number_of_worker_processes
    memory = Gitlab['node']['memory']['total'].to_i - 1258291
    if WebServerHelper.service_name == 'unicorn'
      Unicorn.workers(memory)
    else
      Puma.workers(memory)
    end
  end
end
