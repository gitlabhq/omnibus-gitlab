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

####
# omnibus options
####
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
default['gitlab']['user']['git_user_name'] = "GitLab"
default['gitlab']['user']['git_user_email'] = "gitlab@#{node['fqdn']}"


####
# GitLab core
####
default['gitlab']['gitlab-rails']['enable'] = true
default['gitlab']['gitlab-rails']['ha'] = false
default['gitlab']['gitlab-rails']['dir'] = "/var/opt/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['log_directory'] = "/var/log/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['environment'] = 'production'
default['gitlab']['gitlab-rails']['umask'] = "0022"

default['gitlab']['gitlab-rails']['repositories_path'] = "/var/opt/gitlab/repositories"
default['gitlab']['gitlab-rails']['satellites_path'] = "/var/opt/gitlab/gitlab-satellites"
default['gitlab']['gitlab-rails']['internal_api_url'] = "http://localhost:8080"
default['gitlab']['gitlab-rails']['external_fqdn'] = node['fqdn']
default['gitlab']['gitlab-rails']['external_port'] = 80
default['gitlab']['gitlab-rails']['external_https'] = false
default['gitlab']['gitlab-rails']['notification_email'] = "gitlab@#{node['fqdn']}"
default['gitlab']['gitlab-rails']['support_email'] = "support@example.com"
default['gitlab']['gitlab-rails']['uploads_directory'] = "/var/opt/gitlab/uploads"
default['gitlab']['gitlab-rails']['rate_limit_requests_per_period'] = 10
default['gitlab']['gitlab-rails']['rate_limit_period'] = 60


####
# Unicorn
####
default['gitlab']['unicorn']['enable'] = true
default['gitlab']['unicorn']['log_directory'] = "/var/log/gitlab/unicorn"
default['gitlab']['unicorn']['worker_processes'] = 2
default['gitlab']['unicorn']['listen'] = '127.0.0.1'
default['gitlab']['unicorn']['port'] = 8080
default['gitlab']['unicorn']['socket'] = '/var/opt/gitlab/gitlab-rails/tmp/sockets/gitlab.socket'
default['gitlab']['unicorn']['tcp_nopush'] = true
default['gitlab']['unicorn']['backlog_socket'] = 64
default['gitlab']['unicorn']['worker_timeout'] = 30


###
# gitlab-shell
###
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


####
# Redis
####
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
