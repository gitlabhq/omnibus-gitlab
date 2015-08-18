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

working_dir = node['gitlab']['gitlab-git-http-server']['dir']
log_dir = node['gitlab']['gitlab-git-http-server']['log_dir']

directory working_dir do
  owner node['gitlab']['user']['username']
  group node['gitlab']['web-server']['username']
  mode '0750'
  recursive true
end
  
directory log_dir do
  owner node['gitlab']['user']['username']
  mode '0700'
  recursive true
end

runit_service 'gitlab-git-http-server' do
  down node['gitlab']['gitlab-git-http-server']['ha']
  options({
    :log_directory => log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-git-http-server'].to_hash)
end
