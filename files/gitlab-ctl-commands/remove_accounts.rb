#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

add_command "remove-accounts", "Delete *all* users and groups used by this package", 1 do
  command = %W( chef-client
                -z
                -c #{base_path}/embedded/cookbooks/solo.rb
                -o recipe[gitlab::remove_accounts])

  status = run_command(command.join(" "))
  remove_old_node_state
  Kernel.exit 1 unless status.success?
end
