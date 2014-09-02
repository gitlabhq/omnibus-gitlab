#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

nginx_dir = node['gitlab']['nginx']['dir']
nginx_etc_dir = File.join(nginx_dir, "etc")
nginx_working_dir = File.join(nginx_dir, "working")
nginx_log_dir = node['gitlab']['nginx']['log_directory']

[
  nginx_dir,
  nginx_etc_dir,
  nginx_working_dir,
  nginx_log_dir,
].each do |dir_name|
  directory dir_name do
    owner node['gitlab']['web-server']['username']
    mode '0700'
    recursive true
  end
end

nginx_config = File.join(nginx_etc_dir, "nginx.conf")
nginx_vars = node['gitlab']['nginx'].to_hash.merge({
  :gitlab_http_config => File.join(nginx_etc_dir, "gitlab-http.conf"),
})

template nginx_vars[:gitlab_http_config] do
  source "nginx-gitlab-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(nginx_vars.merge(
    {
      :fqdn => node['gitlab']['gitlab-rails']['gitlab_host'],
      :https => node['gitlab']['gitlab-rails']['gitlab_https'],
      :socket => node['gitlab']['unicorn']['socket'],
      :port => node['gitlab']['gitlab-rails']['gitlab_port'],
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
end

template nginx_config do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables nginx_vars
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
end

runit_service "nginx" do
  down node['gitlab']['nginx']['ha']
  restart_command 'h' # Restart NGINX using SIGHUP
  options({
    :log_directory => nginx_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['nginx'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start nginx" do
    retries 20
  end
end
