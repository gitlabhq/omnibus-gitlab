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

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/generate_secrets"
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/util"

add_command 'generate-secrets', 'Generates secrets used in gitlab.rb', 2 do |cmd_name|
  begin
    options = GitlabCtl::GenerateSecrets.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{GitlabCtl::GenerateSecrets::USAGE}"
    exit 128
  end

  json_attributes = %(
  {
    "run_list": [
      "recipe[#{GitlabCtl::Util.master_cookbook}::config]",
      "recipe[gitlab::generate_secrets]"
    ],
    "_gitlab_secrets_file_path": "#{options[:secrets_path]}",
    "_skip_generate_secrets": true
  }).strip
  command = %W( cinc-client
                --log_level info
                --local-mode
                --config #{base_path}/embedded/cookbooks/solo.rb
                --json-attributes /dev/stdin)

  cmd = GitlabCtl::Util.run_command(command.join(" "), live: true, input: json_attributes)
  remove_old_node_state
  Kernel.exit 1 unless cmd.status.success?
end
