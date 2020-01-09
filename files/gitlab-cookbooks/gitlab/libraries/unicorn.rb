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

module Unicorn
  class << self
    def parse_variables
      parse_unicorn_listen_address
    end

    def parse_unicorn_listen_address
      unicorn_socket = Gitlab['unicorn']['socket'] || Gitlab['node']['gitlab']['unicorn']['socket']

      # The user has no custom settings for connecting workhorse to unicorn. Let's
      # do what we think is best.
      Gitlab['gitlab_workhorse']['auth_socket'] = unicorn_socket if Gitlab['gitlab_workhorse']['auth_backend'].nil?
    end

    def workers(total_memory = Gitlab['node']['memory']['total'].to_i)
      [
        2, # Two is the minimum or web editor will no longer work.
        [
          worker_cpus,
          worker_memory(total_memory)
        ].min # min because we want to exceed neither CPU nor RAM
      ].max # max because we need at least 2 workers
    end

    # Number of cpus to use for a worker.
    def worker_cpus
      cpus = Gitlab['node']['cpu']['total'].to_i
      # Oversubscribe CPUs by 50% based on typical performance.
      (cpus * 1.5 + 1).to_i
    end

    # See how many worker processes fit in the system.
    # Currently, Unicorn boots at 500-600 MB per process at startup.
    def worker_memory(total_memory, retained_memory = 1572864, per_worker_ram = 614400)
      (total_memory - retained_memory) / per_worker_ram
    end
  end
end
