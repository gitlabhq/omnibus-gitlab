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
gitlab_core_sockets_dir = File.dirname(node['gitlab']['gitlab-core']['unicorn_socket'])
gitlab_core_public_uploads_dir = node['gitlab']['gitlab-core']['uploads_directory']
gitlab_core_log_dir = node['gitlab']['gitlab-core']['log_directory']

[
  gitlab_core_dir,
  gitlab_core_etc_dir,
  gitlab_core_working_dir,
  gitlab_core_tmp_dir,
  gitlab_core_sockets_dir,
  gitlab_core_public_uploads_dir,
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

database_yml = File.join(gitlab_core_etc_dir, "database.yml")

template database_yml do
  source "database.yml.postgresql.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[gitlab-core]' if should_notify
end

link "/opt/gitlab/embedded/service/gitlab-core/config/database.yml" do
  to database_yml
end

gitlab_yml = File.join(gitlab_core_etc_dir, "gitlab.yml")

template gitlab_yml do
  source "gitlab.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-core'].to_hash)
  notifies :restart, 'service[gitlab-core]' if should_notify
end

link "/opt/gitlab/embedded/service/gitlab-core/config/gitlab.yml" do
  to gitlab_yml
end

rack_attack = File.join(gitlab_core_etc_dir, "rack_attack.rb")

template rack_attack do
  source "rack_attack.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-core'].to_hash)
  notifies :restart, 'service[gitlab-core]' if should_notify
end

link "/opt/gitlab/embedded/service/gitlab-core/config/initializers/rack_attack.rb" do
  to rack_attack
end

directory node['gitlab']['gitlab-core']['satellites_path'] do
  owner node['gitlab']['user']['username']
  group node['gitlab']['user']['group']
  recursive true
end


unicorn_listen_tcp = node['gitlab']['gitlab-core']['listen']
unicorn_listen_tcp << ":#{node['gitlab']['gitlab-core']['port']}"
unicorn_listen_socket = node['gitlab']['gitlab-core']['unicorn_socket']

unicorn_config File.join(gitlab_core_etc_dir, "unicorn.rb") do
  listen(
    unicorn_listen_tcp => {
      :tcp_nopush => node['gitlab']['gitlab-core']['tcp_nopush']
    },
    unicorn_listen_socket => {
      :backlog => node['gitlab']['gitlab-core']['backlog_socket'],
    }
  )
  worker_timeout node['gitlab']['gitlab-core']['worker_timeout']
  working_directory gitlab_core_working_dir
  worker_processes node['gitlab']['gitlab-core']['worker_processes']
  preload_app true
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[gitlab-core]' if should_notify
end

# replace empty directories in the Git repo with symlinks to /var/opt/gitlab
{
  "/opt/gitlab/embedded/service/gitlab-core/tmp" => gitlab_core_tmp_dir,
  "/opt/gitlab/embedded/service/gitlab-core/public/uploads" => gitlab_core_public_uploads_dir,
  "/opt/gitlab/embedded/service/gitlab-core/log" => gitlab_core_log_dir
}.each do |link_dir, target_dir|
  directory link_dir do
    action :delete
    recursive true
  end

  link link_dir do
    to target_dir
  end
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

