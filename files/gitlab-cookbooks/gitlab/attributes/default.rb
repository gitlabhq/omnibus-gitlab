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

default['gitlab']['bootstrap']['enable'] = true

####
# The Git User that services run as
####
# The username for the chef services user
default['gitlab']['user']['username'] = "git"
default['gitlab']['user']['group'] = "git"
# The shell for the chef services user
default['gitlab']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['gitlab']['user']['home'] = "/var/opt/gitlab"

-####
-# GitLab core
-####
-default['gitlab']['gitlab-core']['enable'] = true
-default['gitlab']['gitlab-core']['ha'] = false
-default['gitlab']['gitlab-core']['dir'] = "/var/opt/gitlab/gitlab-core"
-default['gitlab']['gitlab-core']['log_directory'] = "/var/log/gitlab/gitlab-core"
-default['gitlab']['gitlab-core']['environment'] = 'production'
-default['gitlab']['gitlab-core']['listen'] = '127.0.0.1'
-default['gitlab']['gitlab-core']['vip'] = '127.0.0.1'
-default['gitlab']['gitlab-core']['port'] = 9462
-default['gitlab']['gitlab-core']['backlog'] = 1024
-default['gitlab']['gitlab-core']['tcp_nodelay'] = true
-default['gitlab']['gitlab-core']['worker_timeout'] = 3600
-default['gitlab']['gitlab-core']['umask'] = "0022"
-default['gitlab']['gitlab-core']['worker_processes'] = 2
-default['gitlab']['gitlab-core']['session_key'] = "_sandbox_session"
-default['gitlab']['gitlab-core']['cookie_domain'] = "all"
-default['gitlab']['gitlab-core']['cookie_secret'] = "47b3b8d95dea455baf32155e95d1e64e"
-default['gitlab']['gitlab-core']['web_ui_client_name'] = "chef-webui"
-default['gitlab']['gitlab-core']['web_ui_admin_user_name'] = "admin"
-default['gitlab']['gitlab-core']['web_ui_admin_default_password'] = "p@ssw0rd1"
-
default['gitlab']['gitlab-core']['repositories_path'] = "/var/opt/gitlab/repositories"
default['gitlab']['gitlab-core']['internal_api_url'] = "http://localhost:8080"

default['gitlab']['gitlab-shell']['log_directory'] = "/var/log/gitlab/gitlab-shell/"


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
default['gitlab']['postgresql']['username'] = "gitlab-psql"
default['gitlab']['postgresql']['shell'] = "/bin/sh"
default['gitlab']['postgresql']['home'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['user_path'] = "/opt/gitlab/embedded/bin:/opt/gitlab/bin:$PATH"
default['gitlab']['postgresql']['sql_user'] = "gitlab"
default['gitlab']['postgresql']['sql_password'] = "snakepliskin"
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

###
# Redis
###
default['gitlab']['redis']['enable'] = true
default['gitlab']['redis']['ha'] = false
default['gitlab']['redis']['dir'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['log_directory'] = "/var/log/gitlab/redis"
default['gitlab']['redis']['svlogd_size'] = 1000000
default['gitlab']['redis']['svlogd_num'] = 10
default['gitlab']['redis']['username'] = "gitlab-redis"
default['gitlab']['redis']['shell'] = "/bin/nologin"
default['gitlab']['redis']['home'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['port'] = 6379
