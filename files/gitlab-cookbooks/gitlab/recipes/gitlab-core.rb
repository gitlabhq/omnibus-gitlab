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
#

gitlab_core_dir = node['gitlab']['gitlab-core']['dir']
gitlab_core_etc_dir = File.join(gitlab_core_dir, "etc")
gitlab_core_working_dir = File.join(gitlab_core_dir, "working")
gitlab_core_tmp_dir = File.join(gitlab_core_dir, "tmp")
gitlab_core_log_dir = node['gitlab']['gitlab-core']['log_directory']

[
  gitlab_core_dir,
  gitlab_core_etc_dir,
  gitlab_core_working_dir,
  gitlab_core_tmp_dir,
  gitlab_core_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['gitlab']['user']['username']
    mode '0700'
    recursive true
  end
end

should_notify = OmnibusHelper.should_notify?("gitlab-core")

secret_token_config = File.join(gitlab_core_etc_dir, "secret")

file secret_token_config do
  content node['gitlab']['gitlab-core']['secret_token']
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[gitlab-core]' if should_notify
end

link "/opt/gitlab/embedded/service/gitlab-core/.secret" do
  to secret_token_config
end

unicorn_listen = node['gitlab']['gitlab-core']['listen']
unicorn_listen << ":#{node['gitlab']['gitlab-core']['port']}"

unicorn_config File.join(gitlab_core_etc_dir, "unicorn.rb") do
  listen unicorn_listen => {
    :backlog => node['gitlab']['gitlab-core']['backlog'],
    :tcp_nodelay => node['gitlab']['gitlab-core']['tcp_nodelay']
  }
  worker_timeout node['gitlab']['gitlab-core']['worker_timeout']
  working_directory gitlab_core_working_dir
  worker_processes node['gitlab']['gitlab-core']['worker_processes']
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[gitlab-core]' if should_notify
end

link "/opt/gitlab/embedded/service/gitlab-core/tmp" do
  to gitlab_core_tmp_dir
end

link "/opt/gitlab/embedded/service/gitlab-core/log" do
  to gitlab_core_log_dir
end

execute "chown -R #{node['gitlab']['user']['username']} /opt/gitlab/embedded/service/gitlab-core/public"

runit_service "gitlab-core" do
  down node['gitlab']['gitlab-core']['ha']
  options({
    :log_directory => gitlab_core_log_dir
  }.merge(params))
end

if node['gitlab']['bootstrap']['enable']
	execute "/opt/gitlab/bin/gitlab-ctl start gitlab-core" do
		retries 20
	end
end

