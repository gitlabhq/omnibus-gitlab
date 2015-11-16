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
account_helper = AccountHelper.new(node)

working_dir = node['gitlab']['gitlab-workhorse']['dir']
log_dir = node['gitlab']['gitlab-workhorse']['log_dir']

directory working_dir do
  owner account_helper.gitlab_user
  group account_helper.web_server_group
  mode '0750'
  recursive true
end

directory log_dir do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

runit_service 'gitlab-workhorse' do
  down node['gitlab']['gitlab-workhorse']['ha']
  options({
    :log_directory => log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-workhorse'].to_hash)
end

file File.join(working_dir, "VERSION") do
  content GGHSHelper.version
  notifies :restart, "service[gitlab-workhorse]"
end
