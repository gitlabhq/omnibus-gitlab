#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

nginx_helper = OmnibusGitlab::NginxHelper.new(node)

nginx_configuration 'gitlab-workhorse-upstream' do
  path nginx_helper.upstream_definition_conf_path('gitlab-workhorse')
  action :delete
end

nginx_configuration 'rails' do
  action :delete
end

nginx_configuration 'smartcard' do
  action :delete
end

nginx_configuration 'health' do
  path nginx_helper.service_conf_path('health', suffix: 'partial')
  action :delete
end

nginx_configuration 'rails-metrics' do
  path nginx_helper.extra_metrics_conf_path('gitlab-rails')
  action :delete
end
