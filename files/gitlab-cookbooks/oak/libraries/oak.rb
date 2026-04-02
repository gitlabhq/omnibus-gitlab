# Copyright:: Copyright (c) 2026 GitLab Inc.
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

# OAK (Omnibus-to-Kubernetes bridge) provides configuration and helpers for
# Omnibus components that need to communicate with services deployed in a
# Kubernetes cluster (e.g. OpenBao as an Advanced Component).
module Oak
  class << self
    def parse_variables
      return unless enabled?

      raise "OAK is enabled but `oak['network_address']` is not set." if Gitlab['oak']['network_address'].nil? || Gitlab['oak']['network_address'].empty?
    end

    # Returns true when OAK integration is explicitly enabled by the user.
    def enabled?
      !!Gitlab['oak']['enable']
    end
  end
end
