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

module Puma
  class << self
    def parse_variables
      only_one_allowed!
    end

    def only_one_allowed!
      return unless Services.enabled?('unicorn') && Services.enabled?('puma')

      raise 'Only one web server (Puma or Unicorn) can be enabled at the same time!'
    end

    def workers(total_memory = Gitlab['node']['memory']['total'].to_i)
      [
        2, # Two is the minimum or web editor will no longer work.
        [
          Gitlab['node']['cpu']['total'].to_i,
          worker_memory(total_memory).to_i,
        ].min # min because we want to exceed neither CPU nor RAM
      ].max # max because we need at least 2 workers
    end

    # See how many worker processes fit in the system.
    # Reserve 1.5G of memory for other processes.
    # Currently, Puma workers can use 1GB per process.
    def worker_memory(total_memory, reserved_memory = 1572864, per_worker_ram = 1048576)
      (total_memory - reserved_memory) / per_worker_ram
    end
  end
end
