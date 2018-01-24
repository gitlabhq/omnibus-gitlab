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

module Sentinel
  class << self
    def parse_variables
      parse_sentinel_settings if sentinel_enabled?
    end

    def parse_sentinel_settings
      # If sentinel['announce_ip'] is not defined, we infer the value from redis['announce_ip']
      Gitlab['sentinel']['announce_ip'] ||= Gitlab['redis']['announce_ip']
      # If sentinel['announce_port'] is not defined, we infer the value from sentinel['port']
      Gitlab['sentinel']['announce_port'] ||= Gitlab['sentinel']['port']
    end

    private

    def sentinel_enabled?
      Gitlab['redis_sentinel_role']['enable']
    end

    def node
      Gitlab[:node]
    end
  end
end
