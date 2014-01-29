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
default['chef_server']['api_version'] = "11.0.2"
default['chef_server']['flavor'] = "osc" # Open Source Chef

default['chef_server']['notification_email'] = "info@example.com"
default['chef_server']['bootstrap']['enable'] = true

####
# The Chef User that services run as
####
# The username for the chef services user
default['chef_server']['user']['username'] = "chef_server"
# The shell for the chef services user
default['chef_server']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['chef_server']['user']['home'] = "/opt/chef-server/embedded"

####
# Chef Server WebUI
####
default['chef_server']['chef-server-webui']['enable'] = true
default['chef_server']['chef-server-webui']['ha'] = false
default['chef_server']['chef-server-webui']['dir'] = "/var/opt/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['log_directory'] = "/var/log/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['environment'] = 'chefserver'
default['chef_server']['chef-server-webui']['listen'] = '127.0.0.1'
default['chef_server']['chef-server-webui']['vip'] = '127.0.0.1'
default['chef_server']['chef-server-webui']['port'] = 9462
default['chef_server']['chef-server-webui']['backlog'] = 1024
default['chef_server']['chef-server-webui']['tcp_nodelay'] = true
default['chef_server']['chef-server-webui']['worker_timeout'] = 3600
default['chef_server']['chef-server-webui']['umask'] = "0022"
default['chef_server']['chef-server-webui']['worker_processes'] = 2
default['chef_server']['chef-server-webui']['session_key'] = "_sandbox_session"
default['chef_server']['chef-server-webui']['cookie_domain'] = "all"
default['chef_server']['chef-server-webui']['cookie_secret'] = "47b3b8d95dea455baf32155e95d1e64e"
default['chef_server']['chef-server-webui']['web_ui_client_name'] = "chef-webui"
default['chef_server']['chef-server-webui']['web_ui_admin_user_name'] = "admin"
default['chef_server']['chef-server-webui']['web_ui_admin_default_password'] = "p@ssw0rd1"

###
# Load Balancer
###
default['chef_server']['lb']['enable'] = true
default['chef_server']['lb']['vip'] = "127.0.0.1"
default['chef_server']['lb']['api_fqdn'] = node['fqdn']
default['chef_server']['lb']['web_ui_fqdn'] = node['fqdn']
default['chef_server']['lb']['cache_cookbook_files'] = false
default['chef_server']['lb']['debug'] = false
default['chef_server']['lb']['upstream']['erchef'] = [ "127.0.0.1" ]
default['chef_server']['lb']['upstream']['chef-server-webui'] = [ "127.0.0.1" ]
default['chef_server']['lb']['upstream']['bookshelf'] = [ "127.0.0.1" ]

####
# Nginx
####
default['chef_server']['nginx']['enable'] = true
default['chef_server']['nginx']['ha'] = false
default['chef_server']['nginx']['dir'] = "/var/opt/chef-server/nginx"
default['chef_server']['nginx']['log_directory'] = "/var/log/chef-server/nginx"
default['chef_server']['nginx']['ssl_port'] = 443
default['chef_server']['nginx']['enable_non_ssl'] = false
default['chef_server']['nginx']['non_ssl_port'] = 80
default['chef_server']['nginx']['server_name'] = node['fqdn']
default['chef_server']['nginx']['url'] = "https://#{node['fqdn']}"
# These options provide the current best security with TSLv1
#default['chef_server']['nginx']['ssl_protocols'] = "-ALL +TLSv1"
#default['chef_server']['nginx']['ssl_ciphers'] = "RC4:!MD5"
# This might be necessary for auditors that want no MEDIUM security ciphers and don't understand BEAST attacks
#default['chef_server']['nginx']['ssl_protocols'] = "-ALL +SSLv3 +TLSv1"
#default['chef_server']['nginx']['ssl_ciphers'] = "HIGH:!MEDIUM:!LOW:!ADH:!kEDH:!aNULL:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
# The following favors performance and compatibility, addresses BEAST, and should pass a PCI audit
default['chef_server']['nginx']['ssl_protocols'] = "SSLv3 TLSv1"
default['chef_server']['nginx']['ssl_ciphers'] = "RC4-SHA:RC4-MD5:RC4:RSA:HIGH:MEDIUM:!LOW:!kEDH:!aNULL:!ADH:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
default['chef_server']['nginx']['ssl_certificate'] = nil
default['chef_server']['nginx']['ssl_certificate_key'] = nil
default['chef_server']['nginx']['ssl_country_name'] = "US"
default['chef_server']['nginx']['ssl_state_name'] = "WA"
default['chef_server']['nginx']['ssl_locality_name'] = "Seattle"
default['chef_server']['nginx']['ssl_company_name'] = "YouCorp"
default['chef_server']['nginx']['ssl_organizational_unit_name'] = "Operations"
default['chef_server']['nginx']['ssl_email_address'] = "you@example.com"
default['chef_server']['nginx']['worker_processes'] = node['cpu']['total'].to_i
default['chef_server']['nginx']['worker_connections'] = 10240
default['chef_server']['nginx']['sendfile'] = 'on'
default['chef_server']['nginx']['tcp_nopush'] = 'on'
default['chef_server']['nginx']['tcp_nodelay'] = 'on'
default['chef_server']['nginx']['gzip'] = "on"
default['chef_server']['nginx']['gzip_http_version'] = "1.0"
default['chef_server']['nginx']['gzip_comp_level'] = "2"
default['chef_server']['nginx']['gzip_proxied'] = "any"
default['chef_server']['nginx']['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
default['chef_server']['nginx']['keepalive_timeout'] = 65
default['chef_server']['nginx']['client_max_body_size'] = '250m'
default['chef_server']['nginx']['cache_max_size'] = '5000m'

###
# PostgreSQL
###
default['chef_server']['postgresql']['enable'] = true
default['chef_server']['postgresql']['ha'] = false
default['chef_server']['postgresql']['dir'] = "/var/opt/chef-server/postgresql"
default['chef_server']['postgresql']['data_dir'] = "/var/opt/chef-server/postgresql/data"
default['chef_server']['postgresql']['log_directory'] = "/var/log/chef-server/postgresql"
default['chef_server']['postgresql']['svlogd_size'] = 1000000
default['chef_server']['postgresql']['svlogd_num'] = 10
default['chef_server']['postgresql']['username'] = "opscode-pgsql"
default['chef_server']['postgresql']['shell'] = "/bin/sh"
default['chef_server']['postgresql']['home'] = "/var/opt/chef-server/postgresql"
default['chef_server']['postgresql']['user_path'] = "/opt/chef-server/embedded/bin:/opt/chef-server/bin:$PATH"
default['chef_server']['postgresql']['sql_user'] = "opscode_chef"
default['chef_server']['postgresql']['sql_password'] = "snakepliskin"
default['chef_server']['postgresql']['sql_ro_user'] = "opscode_chef_ro"
default['chef_server']['postgresql']['sql_ro_password'] = "shmunzeltazzen"
default['chef_server']['postgresql']['vip'] = "127.0.0.1"
default['chef_server']['postgresql']['port'] = 5432
default['chef_server']['postgresql']['listen_address'] = 'localhost'
default['chef_server']['postgresql']['max_connections'] = 200
default['chef_server']['postgresql']['md5_auth_cidr_addresses'] = [ ]
default['chef_server']['postgresql']['trust_auth_cidr_addresses'] = [ '127.0.0.1/32', '::1/128' ]
default['chef_server']['postgresql']['shmmax'] = kernel['machine'] =~ /x86_64/ ? 17179869184 : 4294967295
default['chef_server']['postgresql']['shmall'] = kernel['machine'] =~ /x86_64/ ? 4194304 : 1048575

# Resolves CHEF-3889
if (node['memory']['total'].to_i / 4) > ((node['chef_server']['postgresql']['shmmax'].to_i / 1024) - 2097152)
  # guard against setting shared_buffers > shmmax on hosts with installed RAM > 64GB
  # use 2GB less than shmmax as the default for these large memory machines
  default['chef_server']['postgresql']['shared_buffers'] = "14336MB"
else
  default['chef_server']['postgresql']['shared_buffers'] = "#{(node['memory']['total'].to_i / 4) / (1024)}MB"
end

default['chef_server']['postgresql']['work_mem'] = "8MB"
default['chef_server']['postgresql']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / (1024)}MB"
default['chef_server']['postgresql']['checkpoint_segments'] = 10
default['chef_server']['postgresql']['checkpoint_timeout'] = "5min"
default['chef_server']['postgresql']['checkpoint_completion_target'] = 0.9
default['chef_server']['postgresql']['checkpoint_warning'] = "30s"
