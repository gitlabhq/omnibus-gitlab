#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

require_relative '../../package/libraries/helpers/secrets_helper'

Gitlab[:node] = node

if node['package']['generate_secrets_json_file'] == true
  warning_message = <<~EOS
    You have enabled writing to the default secrets file location with package['generate_secrets_json_file'] in the gitlab.rb file which is not compatible with this command.
    Use 'gitlab-ctl reconfigure' to generate secrets instead and copy the resulting #{SecretsHelper::SECRETS_FILE} file.
  EOS
  LoggingHelper.warning(warning_message)
  return
end

secrets_file = node[SecretsHelper::SECRETS_FILE_CHEF_ATTR] || SecretsHelper::SECRETS_FILE
node.override[SecretsHelper::SKIP_GENERATE_SECRETS_CHEF_ATTR] = false
Gitlab.generate_secrets(node['fqdn'], secrets_file)
