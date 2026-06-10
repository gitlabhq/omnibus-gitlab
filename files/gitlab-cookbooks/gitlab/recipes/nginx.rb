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

include_recipe 'nginx::directory'

omnibus_helper = OmnibusHelper.new(node)

nginx_helper = OmnibusGitlab::NginxHelper.new(node)
gitlab_rails_http_conf = nginx_helper.service_conf_path('rails')
gitlab_rails_smartcard_http_conf = nginx_helper.service_conf_path('smartcard')
# Health configuration is not to be included in global nginx.conf file. It is
# only included from the rails conf file. Hence it gets a .partial suffix
gitlab_rails_health_conf = nginx_helper.service_conf_path('health', suffix: 'partial')

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
  cookbook 'gitlab'
  source "nginx-gitlab-workhorse-upstream.conf.erb"
  path nginx_helper.upstream_definition_conf_path('gitlab-workhorse')
  variables({
              workhorse_scheme: workhorse_scheme,
              workhorse_listen_addr: workhorse_listen_addr
            })
end

nginx_configuration 'rails' do
  cookbook 'gitlab'
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
  cookbook 'gitlab'
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
  cookbook 'gitlab'
  path gitlab_rails_health_conf
  variables(
    nginx_gitlab_http_vars
  )

  action(gitlab_rails_enabled || gitlab_rails_smartcard_enabled ? :create : :delete)
end

nginx_configuration 'rails-metrics' do
  source "nginx-gitlab-rails-metrics.conf.erb"
  cookbook 'gitlab'
  path nginx_helper.extra_metrics_conf_path('gitlab-rails')
  variables({
              options: node['gitlab']['nginx']['status']['options'],
            })
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
