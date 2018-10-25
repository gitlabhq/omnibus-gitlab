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

account_helper = AccountHelper.new(node)

working_dir = "/opt/gitlab/embedded/service/gitlab-rails"
log_directory = node['gitlab']['storage-check']['log_directory']

directory log_directory do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

runit_service 'storage-check' do
  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    working_dir: working_dir,
    log_directory: log_directory,
    storage_check_target: node['gitlab']['storage-check']['target']
  }.merge(params))

  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['storage-check'].to_hash)
end
