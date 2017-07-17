#
# Copyright:: Copyright (c) 2016 GitLab B.V.
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

require_relative 'sidekiq_cluster.rb'
require_relative 'gitlab_geo.rb'

module GitlabEE
  class << self
    def generate_hash
      # NOTE: If you are adding a new service
      # and that service has logging, make sure you add the service to
      # the array in parse_udp_log_shipping.
      #
      # Add to the list below any service that has additional EE specific
      # behavior or is impacted by an EE role definition
      results = { 'gitlab' => {} }
      [
        'sidekiq_cluster',
        'geo_secondary',
        'geo_postgresql',
        'geo_logcursor',
        'postgresql', # impacted by role
        'gitlab_rails' # impacted by role
      ].each do |key|
        rkey = key.tr('_', '-')
        results['gitlab'][rkey] = Gitlab[key]
      end

      results
    end

    def generate_config
      SidekiqCluster.parse_variables
      GitlabGeo.parse_variables
      # The last step is to convert underscores to hyphens in top-level keys
      generate_hash
    end
  end
end
