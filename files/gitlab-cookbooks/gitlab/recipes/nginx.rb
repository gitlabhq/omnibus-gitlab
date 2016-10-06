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
account_helper = AccountHelper.new(node)

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
    group account_helper.web_server_group
    mode '0750'
    recursive true
  end
end

link File.join(nginx_dir, "logs") do
  to nginx_log_dir
end

nginx_config = File.join(nginx_conf_dir, "nginx.conf")

gitlab_rails_http_conf = File.join(nginx_conf_dir, "gitlab-http.conf")
gitlab_pages_http_conf = File.join(nginx_conf_dir, "gitlab-pages.conf")
gitlab_registry_http_conf = File.join(nginx_conf_dir, "gitlab-registry.conf")
gitlab_mattermost_http_conf = File.join(nginx_conf_dir, "gitlab-mattermost-http.conf")
nginx_status_conf = File.join(nginx_conf_dir, "nginx-status.conf")

# If the service is enabled, check if we are using internal nginx
gitlab_rails_enabled = if node['gitlab']['gitlab-rails']['enable']
                         node['gitlab']['nginx']['enable']
                       else
                         false
                       end

gitlab_mattermost_enabled = if node['gitlab']['mattermost']['enable']
                              node['gitlab']['mattermost-nginx']['enable']
                            else
                              false
                            end

gitlab_pages_enabled = if node['gitlab']['gitlab-rails']['pages_enabled']
                         node['gitlab']['pages-nginx']['enable']
                       else
                         false
                       end

gitlab_registry_enabled = if node['gitlab']['registry']['enable']
                         node['gitlab']['registry-nginx']['enable']
                       else
                         false
                       end

nginx_status_enabled = node['gitlab']['nginx']['status']['enable']

# Include the config file for gitlab-rails in nginx.conf later
nginx_vars = node['gitlab']['nginx'].to_hash.merge({
               :gitlab_http_config => gitlab_rails_enabled ? gitlab_rails_http_conf : nil
             })

# Include the config file for gitlab mattermost in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
               :gitlab_mattermost_http_config => gitlab_mattermost_enabled ? gitlab_mattermost_http_conf : nil
             })

# Include the config file for gitlab pages in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
                                         :gitlab_pages_http_config => gitlab_pages_enabled ? gitlab_pages_http_conf : nil
                                       })

nginx_vars = nginx_vars.to_hash.merge!({
                                         :gitlab_registry_http_config => gitlab_registry_enabled ? gitlab_registry_http_conf : nil
                                       })

nginx_vars = nginx_vars.to_hash.merge!({
                                         :nginx_status_config => nginx_status_enabled ? nginx_status_conf : nil
                                       })



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
      :port => node['gitlab']['gitlab-rails']['gitlab_port'],
      :relative_url => node['gitlab']['gitlab-rails']['gitlab_relative_url'],
      :kerberos_enabled => node['gitlab']['gitlab-rails']['kerberos_enabled'],
      :kerberos_use_dedicated_port => node['gitlab']['gitlab-rails']['kerberos_use_dedicated_port'],
      :kerberos_port => node['gitlab']['gitlab-rails']['kerberos_port'],
      :kerberos_https => node['gitlab']['gitlab-rails']['kerberos_https'],
      :registry_api_url => node['gitlab']['gitlab-rails']['registry_api_url']
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_rails_enabled ? :create : :delete
end

pages_nginx_vars = node['gitlab']['pages-nginx'].to_hash

if pages_nginx_vars['listen_https'].nil?
  pages_nginx_vars['https'] = node['gitlab']['gitlab-rails']['pages_https']
else
  pages_nginx_vars['https'] = pages_nginx_vars['listen_https']
end

template gitlab_pages_http_conf do
  source "nginx-gitlab-pages-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(pages_nginx_vars.merge(
    {
      pages_path: node['gitlab']['gitlab-rails']['pages_path'],
      pages_listen_proxy: node['gitlab']['gitlab-pages']['listen_proxy']
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_pages_enabled ? :create : :delete
end

registry_nginx_vars = node['gitlab']['registry-nginx'].to_hash

unless registry_nginx_vars['listen_https'].nil?
  registry_nginx_vars['https'] = registry_nginx_vars['listen_https']
end

template gitlab_registry_http_conf do
  source "nginx-gitlab-registry-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(registry_nginx_vars.merge(
    {
      registry_api_url: node['gitlab']['gitlab-rails']['registry_api_url'],
      registry_host: node['gitlab']['gitlab-rails']['registry_host'],
      registry_http_addr: node['gitlab']['registry']['registry_http_addr']
    }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_registry_enabled ? :create : :delete
end

mattermost_nginx_vars = node['gitlab']['mattermost-nginx'].to_hash

if mattermost_nginx_vars['listen_https'].nil?
  mattermost_nginx_vars['https'] = node['gitlab']['mattermost']['service_use_ssl']
else
  mattermost_nginx_vars['https'] = mattermost_nginx_vars['listen_https']
end

template gitlab_mattermost_http_conf do
  source "nginx-gitlab-mattermost-http.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(mattermost_nginx_vars.merge(
   {
     :fqdn => node['gitlab']['mattermost']['host'],
     :port => node['gitlab']['mattermost']['port'],
     :service_port => node['gitlab']['mattermost']['service_port'],
     :service_address => node['gitlab']['mattermost']['service_address']
   }
  ))
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action gitlab_mattermost_enabled ? :create : :delete
end

template nginx_status_conf do
  source "nginx-status.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables ({
    :listen_addresses => nginx_vars['status']['listen_addresses'],
    :fqdn => nginx_vars['status']['fqdn'],
    :port => nginx_vars['status']['port'],
    :options => nginx_vars['status']['options']
  })
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  action nginx_status_enabled ? :create : :delete
end

nginx_vars['gitlab_access_log_format'] = node['gitlab']['nginx']['log_format']
nginx_vars['gitlab_ci_access_log_format'] = node['gitlab']['ci-nginx']['log_format']
nginx_vars['gitlab_mattermost_access_log_format'] = node['gitlab']['mattermost-nginx']['log_format']

template nginx_config do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables nginx_vars
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
end

if nginx_vars.key?('custom_error_pages')
  nginx_vars['custom_error_pages'].each_key do |code|
    template "#{GitlabRails.public_path}/#{code}-custom.html" do
      source "gitlab-rails-error.html.erb"
      owner "root"
      group "root"
      mode "0644"
      variables(
        :code => code,
        :title => nginx_vars['custom_error_pages'][code]['title'],
        :header => nginx_vars['custom_error_pages'][code]['header'],
        :message => nginx_vars['custom_error_pages'][code]['message']
      )
      notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
    end
  end
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
