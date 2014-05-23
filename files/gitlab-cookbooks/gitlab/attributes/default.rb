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
default['gitlab']['user']['uid'] = nil
default['gitlab']['user']['gid'] = nil
# The shell for the chef services user
default['gitlab']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['gitlab']['user']['home'] = "/var/opt/gitlab"
default['gitlab']['user']['git_user_name'] = "GitLab"
default['gitlab']['user']['git_user_email'] = "gitlab@#{node['fqdn']}"


####
# GitLab Rails app
####
default['gitlab']['gitlab-rails']['dir'] = "/var/opt/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['log_directory'] = "/var/log/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['environment'] = 'production'

default['gitlab']['gitlab-rails']['internal_api_url'] = "http://localhost:8080"
default['gitlab']['gitlab-rails']['uploads_directory'] = "/var/opt/gitlab/gitlab-rails/uploads"
default['gitlab']['gitlab-rails']['rate_limit_requests_per_period'] = 10
default['gitlab']['gitlab-rails']['rate_limit_period'] = 60

default['gitlab']['gitlab-rails']['gitlab_host'] = node['fqdn']
default['gitlab']['gitlab-rails']['gitlab_port'] = 80
default['gitlab']['gitlab-rails']['gitlab_https'] = false
default['gitlab']['gitlab-rails']['gitlab_user'] = default['gitlab']['user']['username']
default['gitlab']['gitlab-rails']['gitlab_email_from'] = "gitlab@#{node['fqdn']}"
default['gitlab']['gitlab-rails']['gitlab_support_email'] = "support@localhost"
default['gitlab']['gitlab-rails']['gitlab_default_projects_limit'] = 10
default['gitlab']['gitlab-rails']['gitlab_default_can_create_group'] = nil
default['gitlab']['gitlab-rails']['gitlab_username_changing_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_theme'] = nil
default['gitlab']['gitlab-rails']['gitlab_signup_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_issues'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_merge_requests'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wiki'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wall'] = false
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_snippets'] = false
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_visibility_level'] = "private"
default['gitlab']['gitlab-rails']['issues_tracker_redmine'] = false
default['gitlab']['gitlab-rails']['issues_tracker_redmine_title'] = "Redmine"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_project_url'] = "http://redmine.sample/projects/:issues_tracker_id"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_issues_url'] = "http://redmine.sample/issues/:id"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_new_issue_url'] = "http://redmine.sample/projects/:issues_tracker_id/issues/new"
default['gitlab']['gitlab-rails']['issues_tracker_jira'] = false
default['gitlab']['gitlab-rails']['issues_tracker_jira_title'] = "Atlassian Jira"
default['gitlab']['gitlab-rails']['issues_tracker_jira_project_url'] = "http://jira.sample/issues/?jql=project=:issues_tracker_id"
default['gitlab']['gitlab-rails']['issues_tracker_jira_issues_url'] = "http://jira.sample/browse/:id"
default['gitlab']['gitlab-rails']['issues_tracker_jira_new_issue_url'] = "http://jira.sample/secure/CreateIssue.jspa"
default['gitlab']['gitlab-rails']['gravatar_enabled'] = true
default['gitlab']['gitlab-rails']['gravatar_plain_url'] = nil
default['gitlab']['gitlab-rails']['gravatar_ssl_url'] = nil
default['gitlab']['gitlab-rails']['ldap_enabled'] = false
default['gitlab']['gitlab-rails']['ldap_host'] = nil
default['gitlab']['gitlab-rails']['ldap_base'] = nil
default['gitlab']['gitlab-rails']['ldap_port'] = nil
default['gitlab']['gitlab-rails']['ldap_uid'] = nil
default['gitlab']['gitlab-rails']['ldap_method'] = nil
default['gitlab']['gitlab-rails']['ldap_bind_dn'] = nil
default['gitlab']['gitlab-rails']['ldap_password'] = nil
default['gitlab']['gitlab-rails']['ldap_allow_username_or_email_login'] = nil
default['gitlab']['gitlab-rails']['ldap_user_filter'] = nil
default['gitlab']['gitlab-rails']['ldap_group_base'] = nil
default['gitlab']['gitlab-rails']['satellites_path'] = "/var/opt/gitlab/git-data/gitlab-satellites"
default['gitlab']['gitlab-rails']['backup_path'] = "/var/opt/gitlab/backups"
default['gitlab']['gitlab-rails']['backup_keep_time'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_path'] = "/opt/gitlab/embedded/service/gitlab-shell/"
default['gitlab']['gitlab-rails']['gitlab_shell_repos_path'] = "/var/opt/gitlab/git-data/repositories"
default['gitlab']['gitlab-rails']['gitlab_shell_hooks_path'] = "/opt/gitlab/embedded/service/gitlab-shell/hooks/"
default['gitlab']['gitlab-rails']['gitlab_shell_upload_pack'] = true
default['gitlab']['gitlab-rails']['gitlab_shell_receive_pack'] = true
default['gitlab']['gitlab-rails']['gitlab_shell_ssh_port'] = 22
default['gitlab']['gitlab-rails']['git_bin_path'] = "/opt/gitlab/embedded/bin/git"
default['gitlab']['gitlab-rails']['git_max_size'] = 5242880
default['gitlab']['gitlab-rails']['git_timeout'] = 10

default['gitlab']['gitlab-rails']['aws_enable'] = false
default['gitlab']['gitlab-rails']['aws_access_key_id'] = nil
default['gitlab']['gitlab-rails']['aws_secret_access_key'] = nil
default['gitlab']['gitlab-rails']['aws_bucket'] = nil
default['gitlab']['gitlab-rails']['aws_region'] = nil

default['gitlab']['gitlab-rails']['db_adapter'] = "postgresql"
default['gitlab']['gitlab-rails']['db_encoding'] = "unicode"
default['gitlab']['gitlab-rails']['db_database'] = "gitlabhq_production"
default['gitlab']['gitlab-rails']['db_pool'] = 10
default['gitlab']['gitlab-rails']['db_username'] = "gitlab"
default['gitlab']['gitlab-rails']['db_password'] = "password"
default['gitlab']['gitlab-rails']['db_host'] = "localhost"
default['gitlab']['gitlab-rails']['db_port'] = 5432
default['gitlab']['gitlab-rails']['db_socket'] = nil

####
# Unicorn
####
default['gitlab']['unicorn']['enable'] = true
default['gitlab']['unicorn']['ha'] = false
default['gitlab']['unicorn']['log_directory'] = "/var/log/gitlab/unicorn"
default['gitlab']['unicorn']['worker_processes'] = 2
default['gitlab']['unicorn']['listen'] = '127.0.0.1'
default['gitlab']['unicorn']['port'] = 8080
default['gitlab']['unicorn']['socket'] = '/var/opt/gitlab/gitlab-rails/tmp/sockets/gitlab.socket'
default['gitlab']['unicorn']['tcp_nopush'] = true
default['gitlab']['unicorn']['backlog_socket'] = 64
default['gitlab']['unicorn']['worker_timeout'] = 30

####
# Sidekiq
####
default['gitlab']['sidekiq']['enable'] = true
default['gitlab']['sidekiq']['ha'] = false
default['gitlab']['sidekiq']['log_directory'] = "/var/log/gitlab/sidekiq"


###
# gitlab-shell
###
default['gitlab']['gitlab-shell']['log_directory'] = "/var/log/gitlab/gitlab-shell/"
default['gitlab']['gitlab-shell']['git_data_directory'] = "/var/opt/gitlab/git-data"


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
default['gitlab']['postgresql']['uid'] = nil
default['gitlab']['postgresql']['gid'] = nil
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
default['gitlab']['redis']['uid'] = nil
default['gitlab']['redis']['gid'] = nil
default['gitlab']['redis']['shell'] = "/bin/nologin"
default['gitlab']['redis']['home'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['port'] = 6379


####
# Nginx
####
default['gitlab']['nginx']['enable'] = true
default['gitlab']['nginx']['ha'] = false
default['gitlab']['nginx']['dir'] = "/var/opt/gitlab/nginx"
default['gitlab']['nginx']['log_directory'] = "/var/log/gitlab/nginx"
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
default['gitlab']['nginx']['redirect_http_to_https'] = false
default['gitlab']['nginx']['redirect_http_to_https_port'] = 80
default['gitlab']['nginx']['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
default['gitlab']['nginx']['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
default['gitlab']['nginx']['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4"
default['gitlab']['nginx']['ssl_prefer_server_ciphers'] = "on"
default['gitlab']['nginx']['listen_address'] = '*'
