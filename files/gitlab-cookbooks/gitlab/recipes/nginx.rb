#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab Inc.
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
omnibus_helper = OmnibusHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('nginx')

nginx_helper = OmnibusGitlab::NginxHelper.new(node)

nginx_dir = nginx_helper.nginx_dir
nginx_conf_dir = nginx_helper.conf_dir
nginx_service_conf_dir = nginx_helper.service_conf_dir
nginx_upstream_definition_dir = nginx_helper.upstream_definition_dir
nginx_extra_metrics_dir = nginx_helper.extra_metrics_dir

# These directories do not need to be writable for gitlab-www
[
  nginx_dir,
  nginx_conf_dir,
  nginx_service_conf_dir,
  nginx_upstream_definition_dir,
  nginx_extra_metrics_dir
].each do |dir_name|
  directory dir_name do
    owner 'root'
    group account_helper.web_server_group
    mode '0750'
    recursive true
  end
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

link File.join(nginx_dir, "logs") do
  to logging_settings[:log_directory]
end

nginx_config = File.join(nginx_conf_dir, "nginx.conf")

gitlab_rails_http_conf = nginx_helper.service_conf_path('rails')
gitlab_rails_smartcard_http_conf = nginx_helper.service_conf_path('smartcard')
# Health configuration is not to be included in global nginx.conf file. It is
# only included from the rails conf file. Hence it gets a .partial suffix
gitlab_rails_health_conf = nginx_helper.service_conf_path('health', suffix: 'partial')
gitlab_pages_http_conf = nginx_helper.service_conf_path('pages')
gitlab_registry_http_conf = nginx_helper.service_conf_path('registry')
gitlab_mattermost_http_conf = nginx_helper.service_conf_path('mattermost')
gitlab_kas_http_conf = nginx_helper.service_conf_path('kas')
nginx_status_conf = File.join(nginx_conf_dir, "nginx-status.conf")

# If the service is enabled, check if we are using internal nginx
gitlab_rails_enabled = if node['gitlab']['gitlab_rails']['enable']
                         node['gitlab']['nginx']['enable']
                       else
                         false
                       end

gitlab_rails_smartcard_enabled = if node['gitlab']['gitlab_rails']['enable']
                                   node['gitlab']['nginx']['enable'] && node['gitlab']['gitlab_rails']['smartcard_enabled']
                                 else
                                   false
                                 end

gitlab_mattermost_enabled = if node['mattermost']['enable']
                              node['gitlab']['mattermost_nginx']['enable']
                            else
                              false
                            end

gitlab_pages_enabled = if node['gitlab']['gitlab_rails']['pages_enabled']
                         node['gitlab']['pages_nginx']['enable']
                       else
                         false
                       end

gitlab_registry_enabled = if node['registry']['enable']
                            node['gitlab']['registry_nginx']['enable']
                          else
                            false
                          end

gitlab_kas_enabled = node['gitlab_kas']['enable'] ? node['gitlab']['gitlab_kas_nginx']['enable'] : false

nginx_status_enabled = node['gitlab']['nginx']['status']['enable']

# Include the config file for gitlab-rails in nginx.conf later
nginx_vars = node['gitlab']['nginx'].to_hash.merge({
                                                     gitlab_http_config: gitlab_rails_enabled ? gitlab_rails_http_conf : nil
                                                   })

# Include the config file for gitlab-rails-smartcard in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_smartcard_http_config: gitlab_rails_smartcard_enabled ? gitlab_rails_smartcard_http_conf : nil
                                       })

# Include the config file for gitlab-health in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_health_conf: gitlab_rails_enabled || gitlab_rails_smartcard_enabled ? gitlab_rails_health_conf : nil
                                       })

# Include the config file for gitlab mattermost in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_mattermost_http_config: gitlab_mattermost_enabled ? gitlab_mattermost_http_conf : nil
                                       })

# Include the config file for gitlab pages in nginx.conf later
nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_pages_http_config: gitlab_pages_enabled ? gitlab_pages_http_conf : nil
                                       })

nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_registry_http_config: gitlab_registry_enabled ? gitlab_registry_http_conf : nil
                                       })

nginx_vars = nginx_vars.to_hash.merge!({
                                         gitlab_kas_http_config: gitlab_kas_enabled ? gitlab_kas_http_conf : nil
                                       })

nginx_vars = nginx_vars.to_hash.merge!({
                                         nginx_status_config: nginx_status_enabled ? nginx_status_conf : nil
                                       })

nginx_vars['https'] = if nginx_vars['listen_https'].nil?
                        node['gitlab']['gitlab_rails']['gitlab_https']
                      else
                        nginx_vars['listen_https']
                      end

nginx_vars['gzip'] = node['gitlab']['nginx']['gzip_enabled'] ? "on" : "off"

root_path = node['gitlab']['gitlab_rails']['gitlab_relative_url'] || '/'
api_path = root_path == "/" ? "/api" : File.join(root_path, "/api")

nginx_gitlab_http_vars = nginx_vars.merge(
  fqdn: node['gitlab']['gitlab_rails']['gitlab_host'],
  port: node['gitlab']['gitlab_rails']['gitlab_port'],
  path: root_path,
  api_path: api_path,
  registry_api_url: node['gitlab']['gitlab_rails']['registry_api_url'],
  letsencrypt_enable: node['letsencrypt']['enable'],
  # These addresses will be allowed through plain http, even if `redirect_http_to_https` is enabled
  monitoring_addresses: [
    { url: '/-/health', format: 'txt' },
    { url: '/health_check', format: 'txt' },
    { url: '/health_check/database', format: 'txt' },
    { url: '/health_check/migrations', format: 'txt' },
    { url: '/health_check/cache', format: 'txt' },
    { url: '/health_check/geo', format: 'txt' },
    { url: '/-/readiness', format: 'json' },
    { url: '/-/liveness', format: 'json' },
  ]
)

workhorse_scheme = node['gitlab']['gitlab_workhorse']['listen_network'] == "unix" ? "unix:" : ""
workhorse_listen_addr = node['gitlab']['gitlab_workhorse']['listen_addr']

nginx_configuration 'gitlab-workhorse-upstream' do
  source "nginx-gitlab-workhorse-upstream.conf.erb"
  path nginx_helper.upstream_definition_conf_path('gitlab-workhorse')
  variables({
              workhorse_scheme: workhorse_scheme,
              workhorse_listen_addr: workhorse_listen_addr
            })
end

nginx_configuration 'rails' do
  variables(
    # lazy evaluate here since letsencrypt::enable sets redirect_http_to_https to true
    lazy do
      nginx_gitlab_http_vars.merge(
        {
          kerberos_enabled: node['gitlab']['gitlab_rails']['kerberos_enabled'],
          kerberos_use_dedicated_port: node['gitlab']['gitlab_rails']['kerberos_use_dedicated_port'],
          kerberos_port: node['gitlab']['gitlab_rails']['kerberos_port'],
          kerberos_https: node['gitlab']['gitlab_rails']['kerberos_https'],
          redirect_http_to_https: node['gitlab']['nginx']['redirect_http_to_https']
        }
      )
    end
  )

  action gitlab_rails_enabled ? :create : :delete
end

gitlab_rails_smartcard_nginx_vars = {
  listen_port: node['gitlab']['gitlab_rails']['smartcard_client_certificate_required_port'],
  ssl_client_certificate: node['gitlab']['gitlab_rails']['smartcard_ca_file'],
  ssl_verify_client: 'on',
  ssl_verify_depth: 2,
  proxy_set_headers: nginx_vars['proxy_set_headers'].merge(
    {
      'X-SSL-Client-Certificate' => '$ssl_client_cert'
    }
  ),
  redirect_http_to_https: node['gitlab']['nginx']['redirect_http_to_https']
}

gitlab_rails_smartcard_nginx_vars['fqdn'] = node['gitlab']['gitlab_rails']['smartcard_client_certificate_required_host'] unless node['gitlab']['gitlab_rails']['smartcard_client_certificate_required_host'].nil?

nginx_configuration 'smartcard' do
  source "nginx-gitlab-rails.conf.erb"
  variables(
    # lazy evaluate here since letsencrypt::enable sets redirect_http_to_https to true
    lazy do
      nginx_gitlab_http_vars.merge(gitlab_rails_smartcard_nginx_vars)
    end
  )

  action gitlab_rails_smartcard_enabled ? :create : :delete
end

nginx_configuration 'health' do
  source "nginx-gitlab-health.conf.erb"
  path gitlab_rails_health_conf
  variables(
    nginx_gitlab_http_vars
  )

  action(gitlab_rails_enabled || gitlab_rails_smartcard_enabled ? :create : :delete)
end

pages_nginx_vars = node['gitlab']['pages_nginx'].to_hash

pages_nginx_vars['https'] = if pages_nginx_vars['listen_https'].nil?
                              node['gitlab']['gitlab_rails']['pages_https']
                            else
                              pages_nginx_vars['listen_https']
                            end

nginx_configuration 'pages' do
  variables(pages_nginx_vars.merge(
              {
                pages_path: node['gitlab']['gitlab_rails']['pages_path'],
                pages_listen_proxy: node['gitlab_pages']['listen_proxy']
              }
            ))

  action gitlab_pages_enabled ? :create : :delete
end

registry_nginx_vars = node['gitlab']['registry_nginx'].to_hash

registry_nginx_vars['https'] = registry_nginx_vars['listen_https'] unless registry_nginx_vars['listen_https'].nil?

nginx_configuration 'registry' do
  variables(registry_nginx_vars.merge(
              {
                registry_api_url: node['gitlab']['gitlab_rails']['registry_api_url'],
                fqdn: node['gitlab']['gitlab_rails']['registry_host'],
                port: node['gitlab']['gitlab_rails']['registry_port'],
                registry_http_addr: node['registry']['registry_http_addr'],
                letsencrypt_enable: node['letsencrypt']['enable'],
                redirect_http_to_https: node['gitlab']['registry_nginx']['redirect_http_to_https']
              }
            ))

  action gitlab_registry_enabled ? :create : :delete
end

mattermost_nginx_vars = node['gitlab']['mattermost_nginx'].to_hash

mattermost_nginx_vars['https'] = if mattermost_nginx_vars['listen_https'].nil?
                                   node['mattermost']['service_use_ssl']
                                 else
                                   mattermost_nginx_vars['listen_https']
                                 end

nginx_configuration 'mattermost' do
  variables(mattermost_nginx_vars.merge(
              {
                fqdn: node['mattermost']['host'],
                port: node['mattermost']['port'],
                service_port: node['mattermost']['service_port'],
                service_address: node['mattermost']['service_address'],
                letsencrypt_enable: node['letsencrypt']['enable'],
                redirect_http_to_https: node['gitlab']['mattermost_nginx']['redirect_http_to_https']
              }
            ))

  action gitlab_mattermost_enabled ? :create : :delete
end

gitlab_kas_nginx_vars = node['gitlab']['gitlab_kas_nginx'].to_hash
gitlab_kas_nginx_vars['https'] = gitlab_kas_nginx_vars['listen_https'] unless gitlab_kas_nginx_vars['listen_https'].nil?

nginx_configuration 'kas' do
  variables(gitlab_kas_nginx_vars.merge(
              {
                fqdn: node['gitlab']['gitlab_kas_nginx']['host'],
                listen_port: node['gitlab']['gitlab_kas_nginx']['port'],
                gitlab_kas_listen_address: node['gitlab_kas']['listen_address'],
                gitlab_kas_k8s_proxy_listen_address: node['gitlab_kas']['kubernetes_api_listen_address'],
                gitlab_kas_listen_https: gitlab_kas_nginx_vars['listen_https'],
                letsencrypt_enable: node['letsencrypt']['enable']
              }
            ))

  action gitlab_kas_enabled ? :create : :delete
end

nginx_configuration 'rails-metrics' do
  source "nginx-gitlab-rails-metrics.conf.erb"
  path nginx_helper.extra_metrics_conf_path('gitlab-rails')
  variables({
              options: node['gitlab']['nginx']['status']['options'],
            })
end

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

nginx_vars['gitlab_access_log_format'] = node['gitlab']['nginx']['log_format']
nginx_vars['gitlab_mattermost_access_log_format'] = node['gitlab']['mattermost_nginx']['log_format']
nginx_vars['gitlab_nginx_log_format_escape'] = node['gitlab']['nginx']['log_format_escape']
nginx_vars['gitlab_mattermost_log_format_escape'] = node['gitlab']['mattermost_nginx']['log_format_escape']

template nginx_config do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables nginx_vars
  notifies :restart, 'runit_service[nginx]' if omnibus_helper.should_notify?("nginx")
end

if nginx_vars.key?('custom_error_pages')
  nginx_vars['custom_error_pages'].each_key do |code|
    template "#{GitlabRails.public_path}/#{code}-custom.html" do
      source "gitlab-rails-error.html.erb"
      owner "root"
      group "root"
      mode "0644"
      variables(
        code: code,
        title: nginx_vars['custom_error_pages'][code]['title'],
        header: nginx_vars['custom_error_pages'][code]['header'],
        message: nginx_vars['custom_error_pages'][code]['message']
      )
      notifies :restart, 'runit_service[nginx]' if omnibus_helper.should_notify?("nginx")
    end
  end
end

include_recipe 'nginx::enable'

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start nginx" do
    retries 20
  end
end

# Cleanup old config files
# TODO: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9316
%w[
  http
  smartcard-http
  mattermost-http
  pages
  registry
  kas
].each do |component|
  old_conf_file = File.join(nginx_conf_dir, "gitlab-#{component}.conf")

  template old_conf_file do
    action :delete
  end
end
