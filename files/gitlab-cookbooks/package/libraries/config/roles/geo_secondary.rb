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

require_relative '../../settings_dsl.rb'

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
    Gitlab['gitlab_rails']['enable'] = rails_needed?
    Gitlab[WebServerHelper.service_name]['worker_processes'] ||= number_of_worker_processes
  end

  def self.rails_needed?
    return Gitlab['gitlab_rails']['enable'] unless Gitlab['gitlab_rails']['enable'].nil?

    # If a service is explicitly set, it will be set in Gitlab[svc]['enable'].
    # If it us auto-enabled, it will be set to true in Gitlab[:node][svc]['enable']
    %w(puma sidekiq geo_logcursor).each do |svc|
      # If the service is explicitly enabled
      return true if Gitlab[svc]['enable']
      # If the service is auto-enabled, and not explicitly disabled
      return true if Gitlab[:node]['gitlab'][SettingsDSL::Utils.sanitized_key(svc)]['enable'] && Gitlab[svc]['enable'].nil?
    end

    return true if Gitlab['gitaly']['enable'] || (Gitlab[:node]['gitaly']['enable'] && Gitlab['gitaly']['enable'].nil?)

    false
  end

  # running as a secondary requires several additional processes (geo-postgresql, geo-logcursor, etc).
  # allow more memory for them by reducing the number of Puma workers. Each one is minimum
  # 400MB, so free up 1.2GB.  But maintain our 2 worker minimum. #2858
  def self.number_of_worker_processes
    memory = Gitlab['node']['memory']['total'].to_i - 1258291
    Puma.workers(memory)
  end
end
