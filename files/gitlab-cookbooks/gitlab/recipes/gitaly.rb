#
# Copyright:: Copyright (c) 2016 GitLab B.V.
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
account_helper = AccountHelper.new(node)

working_dir = node['gitlab']['gitaly']['dir']
log_directory = node['gitlab']['gitaly']['log_directory']
env_directory = node['gitlab']['gitaly']['env_directory']

directory working_dir do
  owner account_helper.gitlab_user
  mode '0750'
  recursive true
end

directory log_directory do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

env_dir env_directory do
  variables node['gitlab']['gitaly']['env']
  restarts ["service[gitaly]"]
end

runit_service 'gitaly' do
  down node['gitlab']['gitaly']['ha']
  options({
    :log_directory => log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitaly'].to_hash)
end
