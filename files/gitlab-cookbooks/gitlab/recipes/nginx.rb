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
nginx_conf_dir = File.join(nginx_dir, "conf")
nginx_log_dir = node['gitlab']['nginx']['log_directory']

# These directories do not need to be writable for gitlab-www
[
  nginx_dir,
  nginx_conf_dir,
  nginx_log_dir,
].each do |dir_name|
  directory dir_name do
    owner 'root'
    group node['gitlab']['web-server']['group']
    mode '0750'
    recursive true
  end
end

link File.join(nginx_dir, "logs") do
  to nginx_log_dir
end

nginx_config = File.join(nginx_conf_dir, "nginx.conf")

gitlab_rails_http_conf = File.join(nginx_conf_dir, "gitlab-http.conf")
gitlab_ci_http_conf = File.join(nginx_conf_dir, "gitlab-ci-http.conf")

# If the service is enabled, check if we are using internal nginx
gitlab_rails_enabled = if node['gitlab']['gitlab-rails']['enable']
                         node['gitlab']['nginx']['enable']
                       else
                         false
                       end

gitlab_ci_enabled = if node['gitlab']['gitlab-ci']['enable']
                      node['gitlab']['ci-nginx']['enable']
                    else
                      false
                    end

# Include the config file for gitlab-rails in nginx.conf later
nginx_vars = node['gitlab']['nginx'].to_hash.merge({
               :gitlab_http_config => gitlab_rails_enabled ? gitlab_rails_http_conf : nil
             })

# Include the config file for gitlab-ci in nginx.conf later
nginx_vars =  nginx_vars.merge!(
                :gitlab_ci_http_config => gitlab_ci_enabled ? gitlab_ci_http_conf : nil
              )
if nginx_vars['listen_https'].nil?
  nginx_vars['https'] = node['gitlab']['gitlab-rails']['gitlab_https']
else
  nginx_vars['https'] = nginx_vars['listen_https']
end

template gitlab_rails_http_conf do
  source "nginx-gitlab-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(nginx_vars.merge(
    {
      :fqdn => node['gitlab']['gitlab-rails']['gitlab_host'],
      :socket => node['gitlab']['unicorn']['socket']
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_rails_enabled ? :create : :delete
end

ci_nginx_vars = node['gitlab']['ci-nginx'].to_hash

if ci_nginx_vars['listen_https'].nil?
  ci_nginx_vars['https'] = node['gitlab']['gitlab-ci']['gitlab_ci_https']
else
  ci_nginx_vars['https'] = ci_nginx_vars['listen_https']
end

template gitlab_ci_http_conf do
  source "nginx-gitlab-ci-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(ci_nginx_vars.merge(
    {
      :fqdn => node['gitlab']['gitlab-ci']['gitlab_ci_host'],
      :socket => node['gitlab']['ci-unicorn']['socket']
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_ci_enabled ? :create : :delete
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
