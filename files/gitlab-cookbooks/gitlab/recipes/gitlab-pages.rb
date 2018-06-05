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

working_dir = node['gitlab']['gitlab-pages']['dir']
log_directory = node['gitlab']['gitlab-pages']['log_directory']
gitlab_pages_static_etc_dir = "/opt/gitlab/etc/gitlab-pages"
admin_secret_path = "/var/opt/gitlab/gitlab-pages/admin.secret"

[
  working_dir,
  log_directory,
  gitlab_pages_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/bin/gitlab-pages -version")
  notifies :restart, "service[gitlab-pages]"
end

template admin_secret_path do
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0640"
  variables(secret_token: node['gitlab']['gitlab-pages']['admin_secret_token'])
  notifies :restart, "service[gitlab-pages]"
end

runit_service 'gitlab-pages' do
  options({
    log_directory: log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-pages'].to_hash)
end
