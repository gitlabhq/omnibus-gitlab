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
nginx_log_dir = node['gitlab']['nginx']['log_directory']

runit_service "nginx" do
  start_down node['gitlab']['nginx']['ha']
  options({
    log_directory: nginx_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['nginx'].to_hash)
end

execute 'reload nginx' do
  command 'gitlab-ctl hup nginx'
  action :nothing
end
