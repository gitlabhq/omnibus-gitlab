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

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/selinux"
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/util"

add_command_under_category('apply-sepolicy',
                           'SELinux Controls',
                           'Apply GitLab SELinux policy to managed files',
                           2) do
  options = GitlabCtl::SELinuxManager.parse_options(ARGV, "Usage: gitlab-ctl apply-sepolicy [options]")

  node_attributes = GitlabCtl::Util.get_node_attributes

  result = GitlabCtl::Util.run_command(SELinuxHelper.commands(node_attributes, dry_run: options[:dry_run]))

  log result.stdout if options[:verbose] && !result.stdout.empty?
rescue GitlabCtl::Errors::NodeError => e
  log "Cannot apply SELinux policy and contexts. #{e}"
end
