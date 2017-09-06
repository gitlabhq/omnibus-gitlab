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

module RedisMasterRole
  def self.load_role
    master_role = Gitlab['redis_master_role']['enable']
    slave_role  = Gitlab['redis_slave_role']['enable']

    raise 'Cannot define both redis_master_role and redis_slave_role in the same machine.' if master_role && slave_role

    Services.enable_group('redis_node') if master_role || slave_role
  end
end
