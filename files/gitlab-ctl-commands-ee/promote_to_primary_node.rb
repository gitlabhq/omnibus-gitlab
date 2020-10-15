require "#{base_path}/embedded/cookbooks/package/libraries/helpers/gitlab_cluster_helper"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/promote_to_primary_node"

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

add_command_under_category('promote-to-primary-node', 'gitlab-geo', 'Promote to primary node', 2) do |cmd_name, *args|
  def get_ctl_options
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: gitlab-ctl promote-to-primary-node [options]"

      opts.on('-p', '--[no-]confirm-primary-is-down', 'Do not ask for confirmation that primary is down') do |p|
        options[:confirm_primary_is_down] = p
      end

      opts.on('-m', '--skip-preflight-checks', 'Perform promotion without running any preflight checks') do |m|
        options[:skip_preflight_checks] = m
      end

      opts.on('-f', '--force', 'Proceed even if preflight checks fail') do |f|
        options[:force] = f
      end
    end.parse!(ARGV.dup)

    options
  end

  Geo::PromoteToPrimaryNode.new(base_path, get_ctl_options).execute
end
