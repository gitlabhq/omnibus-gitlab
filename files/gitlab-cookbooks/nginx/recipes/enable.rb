#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

include_recipe 'nginx::directory'

omnibus_helper = OmnibusHelper.new(node)
nginx_helper = OmnibusGitlab::NginxHelper.new(node)

nginx_conf_dir = nginx_helper.conf_dir

# NGINX Status configuration
nginx_status_conf = File.join(nginx_conf_dir, "nginx-status.conf")
nginx_status_enabled = node['gitlab']['nginx']['status']['enable']

nginx_vars = node['gitlab']['nginx'].to_hash
nginx_vars['gzip'] = node['gitlab']['nginx']['gzip_enabled'] ? "on" : "off"

nginx_vars = nginx_vars.to_hash.merge!({
                                         nginx_status_config: nginx_status_enabled ? nginx_status_conf : nil
                                       })

template nginx_status_conf do
  source "nginx-status.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({
              listen_addresses: nginx_vars['status']['listen_addresses'],
              fqdn: nginx_vars['status']['fqdn'],
              port: nginx_vars['status']['port'],
              options: nginx_vars['status']['options'],
              vts_enable: nginx_vars['status']['vts_enable']
            })
  notifies :restart, 'runit_service[nginx]' if omnibus_helper.should_notify?("nginx")
  action nginx_status_enabled ? :create : :delete
end

nginx_consul_action = if nginx_status_enabled && Prometheus.service_discovery
                        :create
                      else
                        :delete
                      end

consul_service node['gitlab']['nginx']['consul_service_name'] do
  id 'nginx'
  action nginx_consul_action
  ip_address node['gitlab']['nginx']['status']['listen_addresses'].first
  port node['gitlab']['nginx']['status']['port']
  reload_service false unless Services.enabled?('consul')
end

# NGINX root configuration
nginx_config = File.join(nginx_conf_dir, "nginx.conf")

nginx_vars['gitlab_access_log_format'] = node['gitlab']['nginx']['log_format']
nginx_vars['gitlab_nginx_log_format_escape'] = node['gitlab']['nginx']['log_format_escape']

template nginx_config do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables nginx_vars
  notifies :restart, 'runit_service[nginx]' if omnibus_helper.should_notify?("nginx")
end

# Runit file for service
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('nginx')

runit_service "nginx" do
  start_down node['gitlab']['nginx']['ha']
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
  }.merge(params))
  log_options logging_settings[:options]
end

version_file 'Create version file for NGINX' do
  version_file_path File.join(node['gitlab']['nginx']['dir'], 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/sbin/nginx -ver 2>&1'
  notifies :restart, 'runit_service[nginx]'
end

execute 'reload nginx' do
  command 'gitlab-ctl hup nginx'
  action :nothing
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start nginx" do
    retries 20
  end
end
