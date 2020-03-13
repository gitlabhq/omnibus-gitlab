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

module SidekiqCluster
  class << self
    def parse_variables
      return unless Gitlab['sidekiq_cluster']['enable']

      # Ensure queues is an array
      Gitlab['sidekiq_cluster']['queue_groups'] = Array(Gitlab['sidekiq_cluster']['queue_groups'])

      # Error out if the queue hasn't been set
      raise "The sidekiq_cluster queue_groups must be set in order to use the sidekiq-cluster service" if Gitlab['sidekiq_cluster']['queue_groups'].empty?
    end
  end
end
