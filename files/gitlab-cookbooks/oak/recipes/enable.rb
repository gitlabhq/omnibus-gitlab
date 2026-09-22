# Copyright:: Copyright (c) 2026 GitLab Inc.
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
# For each configured OAK component, render the nginx configuration and, when
# the component ships a Helm chart, a ready-to-use Helm values file (or delete
# it when the component is disabled). The Helm values template is inferred from
# the component name: #{name}-helm-values.yaml.erb

include_recipe 'nginx::directory'

# Template variables for a component's nginx server block. Each component owns
# its own set; the shared node['nginx'] hash supplies listen addresses, TLS
# ciphers, and log settings.
oak_nginx_variables = lambda do |name, config|
  case name
  when 'openbao'
    node['nginx'].to_hash.merge(
      fqdn: config['fqdn'],
      listen_port: config['listen_port'],
      openbao_internal_url: config['internal_url'],
      https: config['https'],
      ssl_certificate: config['ssl_certificate'],
      ssl_certificate_key: config['ssl_certificate_key'],
      redirect_http_to_https: config['redirect_http_to_https'],
      letsencrypt_enable: node['letsencrypt']['enable']
    )
  else
    {}
  end
end

# Template variables for a component's Helm values file.
oak_helm_variables = lambda do |name, config|
  case name
  when 'openbao'
    {
      network_address: node['oak']['network_address'],
      postgresql_port: node['postgresql']['port'],
      gitlab_url: node['gitlab']['external_url'],
      openbao_external_url: config['external_url']
    }
  else
    {}
  end
end

node['oak']['components'].each do |name, config|
  generate_nginx_conf = if node['nginx']['enable']
                          !!config['enable']
                        else
                          false
                        end

  nginx_configuration name do
    cookbook 'oak'
    variables(
      # lazy evaluate here since letsencrypt::enable sets redirect_http_to_https to true
      lazy { oak_nginx_variables.call(name, config) }
    )
    action generate_nginx_conf ? 'create' : 'delete'
  end

  helm_values_path = node.dig('oak', 'components', name, 'helm_values_path')
  next unless helm_values_path

  template helm_values_path do
    source "#{name}-helm-values.yaml.erb"
    cookbook 'oak'
    owner 'root'
    group 'root'
    mode '0640'
    variables(lazy { oak_helm_variables.call(name, config) })
    action node.dig('oak', 'components', name, 'enable') ? :create : :delete
  end
end
