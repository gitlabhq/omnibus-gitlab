#
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

add_command_under_category 'set-geo-primary-node', 'gitlab-geo', 'Make this node the Geo primary', 2 do |cmd_name|
  service_name = 'unicorn'

  unless service_enabled?(service_name)
    log 'unicorn is not enabled, exiting...'
    Kernel.exit 1
  end

  command = "gitlab-rake geo:set_primary_node"

  run_command(command)
end
