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
# When OAK is disabled globally, remove the nginx configuration and any Helm
# values files that were previously generated for OAK components.

node['oak']['components'].each do |name, _config|
  nginx_configuration name do
    action :delete
  end

  helm_values_path = node.dig('oak', 'components', name, 'helm_values_path')
  next unless helm_values_path

  file helm_values_path do
    action :delete
  end
end
