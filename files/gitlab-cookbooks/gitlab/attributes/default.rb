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

###
# High level options
###
default['gitlab']['notification_email'] = "info@example.com"
default['gitlab']['bootstrap']['enable'] = true

####
# The Chef User that services run as
####
# The username for the chef services user
default['gitlab']['user']['username'] = "gitlab"
# The shell for the chef services user
default['gitlab']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['gitlab']['user']['home'] = "/opt/gitlab/embedded"

####
# Chef Server WebUI
####
default['gitlab']['gitlab-webui']['enable'] = true
default['gitlab']['gitlab-webui']['ha'] = false
default['gitlab']['gitlab-webui']['dir'] = "/var/opt/gitlab/gitlab-webui"
default['gitlab']['gitlab-webui']['log_directory'] = "/var/log/gitlab/gitlab-webui"
default['gitlab']['gitlab-webui']['environment'] = 'chefserver'
default['gitlab']['gitlab-webui']['listen'] = '127.0.0.1'
default['gitlab']['gitlab-webui']['vip'] = '127.0.0.1'
default['gitlab']['gitlab-webui']['port'] = 9462
default['gitlab']['gitlab-webui']['backlog'] = 1024
default['gitlab']['gitlab-webui']['tcp_nodelay'] = true
default['gitlab']['gitlab-webui']['worker_timeout'] = 3600
default['gitlab']['gitlab-webui']['umask'] = "0022"
default['gitlab']['gitlab-webui']['worker_processes'] = 2
default['gitlab']['gitlab-webui']['session_key'] = "_sandbox_session"
default['gitlab']['gitlab-webui']['cookie_domain'] = "all"
default['gitlab']['gitlab-webui']['cookie_secret'] = "47b3b8d95dea455baf32155e95d1e64e"
default['gitlab']['gitlab-webui']['web_ui_client_name'] = "chef-webui"
default['gitlab']['gitlab-webui']['web_ui_admin_user_name'] = "admin"
default['gitlab']['gitlab-webui']['web_ui_admin_default_password'] = "p@ssw0rd1"

###
# Load Balancer
###
default['gitlab']['lb']['enable'] = true
default['gitlab']['lb']['vip'] = "127.0.0.1"
default['gitlab']['lb']['api_fqdn'] = node['fqdn']
default['gitlab']['lb']['web_ui_fqdn'] = node['fqdn']
default['gitlab']['lb']['cache_cookbook_files'] = false
default['gitlab']['lb']['debug'] = false
default['gitlab']['lb']['upstream']['erchef'] = [ "127.0.0.1" ]
default['gitlab']['lb']['upstream']['gitlab-webui'] = [ "127.0.0.1" ]
default['gitlab']['lb']['upstream']['bookshelf'] = [ "127.0.0.1" ]

####
# Nginx
####
default['gitlab']['nginx']['enable'] = true
default['gitlab']['nginx']['ha'] = false
default['gitlab']['nginx']['dir'] = "/var/opt/gitlab/nginx"
default['gitlab']['nginx']['log_directory'] = "/var/log/gitlab/nginx"
default['gitlab']['nginx']['ssl_port'] = 443
default['gitlab']['nginx']['enable_non_ssl'] = false
default['gitlab']['nginx']['non_ssl_port'] = 80
default['gitlab']['nginx']['server_name'] = node['fqdn']
default['gitlab']['nginx']['url'] = "https://#{node['fqdn']}"
# These options provide the current best security with TSLv1
#default['gitlab']['nginx']['ssl_protocols'] = "-ALL +TLSv1"
#default['gitlab']['nginx']['ssl_ciphers'] = "RC4:!MD5"
# This might be necessary for auditors that want no MEDIUM security ciphers and don't understand BEAST attacks
#default['gitlab']['nginx']['ssl_protocols'] = "-ALL +SSLv3 +TLSv1"
#default['gitlab']['nginx']['ssl_ciphers'] = "HIGH:!MEDIUM:!LOW:!ADH:!kEDH:!aNULL:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
# The following favors performance and compatibility, addresses BEAST, and should pass a PCI audit
default['gitlab']['nginx']['ssl_protocols'] = "SSLv3 TLSv1"
default['gitlab']['nginx']['ssl_ciphers'] = "RC4-SHA:RC4-MD5:RC4:RSA:HIGH:MEDIUM:!LOW:!kEDH:!aNULL:!ADH:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
default['gitlab']['nginx']['ssl_certificate'] = nil
default['gitlab']['nginx']['ssl_certificate_key'] = nil
default['gitlab']['nginx']['ssl_country_name'] = "US"
default['gitlab']['nginx']['ssl_state_name'] = "WA"
default['gitlab']['nginx']['ssl_locality_name'] = "Seattle"
default['gitlab']['nginx']['ssl_company_name'] = "YouCorp"
default['gitlab']['nginx']['ssl_organizational_unit_name'] = "Operations"
default['gitlab']['nginx']['ssl_email_address'] = "you@example.com"
default['gitlab']['nginx']['worker_processes'] = node['cpu']['total'].to_i
default['gitlab']['nginx']['worker_connections'] = 10240
default['gitlab']['nginx']['sendfile'] = 'on'
default['gitlab']['nginx']['tcp_nopush'] = 'on'
default['gitlab']['nginx']['tcp_nodelay'] = 'on'
default['gitlab']['nginx']['gzip'] = "on"
default['gitlab']['nginx']['gzip_http_version'] = "1.0"
default['gitlab']['nginx']['gzip_comp_level'] = "2"
default['gitlab']['nginx']['gzip_proxied'] = "any"
default['gitlab']['nginx']['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
default['gitlab']['nginx']['keepalive_timeout'] = 65
default['gitlab']['nginx']['client_max_body_size'] = '250m'
default['gitlab']['nginx']['cache_max_size'] = '5000m'

###
# PostgreSQL
###
default['gitlab']['postgresql']['enable'] = true
default['gitlab']['postgresql']['ha'] = false
default['gitlab']['postgresql']['dir'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['data_dir'] = "/var/opt/gitlab/postgresql/data"
default['gitlab']['postgresql']['log_directory'] = "/var/log/gitlab/postgresql"
default['gitlab']['postgresql']['svlogd_size'] = 1000000
default['gitlab']['postgresql']['svlogd_num'] = 10
default['gitlab']['postgresql']['username'] = "opscode-pgsql"
default['gitlab']['postgresql']['shell'] = "/bin/sh"
default['gitlab']['postgresql']['home'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['user_path'] = "/opt/gitlab/embedded/bin:/opt/gitlab/bin:$PATH"
default['gitlab']['postgresql']['sql_user'] = "opscode_chef"
default['gitlab']['postgresql']['sql_password'] = "snakepliskin"
default['gitlab']['postgresql']['sql_ro_user'] = "opscode_chef_ro"
default['gitlab']['postgresql']['sql_ro_password'] = "shmunzeltazzen"
default['gitlab']['postgresql']['vip'] = "127.0.0.1"
default['gitlab']['postgresql']['port'] = 5432
default['gitlab']['postgresql']['listen_address'] = 'localhost'
default['gitlab']['postgresql']['max_connections'] = 200
default['gitlab']['postgresql']['md5_auth_cidr_addresses'] = [ ]
default['gitlab']['postgresql']['trust_auth_cidr_addresses'] = [ '127.0.0.1/32', '::1/128' ]
default['gitlab']['postgresql']['shmmax'] = kernel['machine'] =~ /x86_64/ ? 17179869184 : 4294967295
default['gitlab']['postgresql']['shmall'] = kernel['machine'] =~ /x86_64/ ? 4194304 : 1048575

# Resolves CHEF-3889
if (node['memory']['total'].to_i / 4) > ((node['gitlab']['postgresql']['shmmax'].to_i / 1024) - 2097152)
  # guard against setting shared_buffers > shmmax on hosts with installed RAM > 64GB
  # use 2GB less than shmmax as the default for these large memory machines
  default['gitlab']['postgresql']['shared_buffers'] = "14336MB"
else
  default['gitlab']['postgresql']['shared_buffers'] = "#{(node['memory']['total'].to_i / 4) / (1024)}MB"
end

default['gitlab']['postgresql']['work_mem'] = "8MB"
default['gitlab']['postgresql']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / (1024)}MB"
default['gitlab']['postgresql']['checkpoint_segments'] = 10
default['gitlab']['postgresql']['checkpoint_timeout'] = "5min"
default['gitlab']['postgresql']['checkpoint_completion_target'] = 0.9
default['gitlab']['postgresql']['checkpoint_warning'] = "30s"
