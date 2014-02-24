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
# GitLab Rails app
####
default['gitlab']['gitlab-rails']['dir'] = "/var/opt/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['log_directory'] = "/var/log/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['environment'] = 'production'

default['gitlab']['gitlab-rails']['internal_api_url'] = "http://localhost:8080"
default['gitlab']['gitlab-rails']['uploads_directory'] = "/var/opt/gitlab/uploads"
default['gitlab']['gitlab-rails']['rate_limit_requests_per_period'] = 10
default['gitlab']['gitlab-rails']['rate_limit_period'] = 60

default['gitlab']['gitlab-rails']['gitlab_host'] = node['fqdn']
default['gitlab']['gitlab-rails']['gitlab_port'] = 80
default['gitlab']['gitlab-rails']['gitlab_https'] = false
default['gitlab']['gitlab-rails']['gitlab_user'] = "git"
default['gitlab']['gitlab-rails']['gitlab_email_from'] = "gitlab@#{node['fqdn']}"
default['gitlab']['gitlab-rails']['gitlab_support_email'] = "support@localhost"
default['gitlab']['gitlab-rails']['support_email'] = "support@example.com"
default['gitlab']['gitlab-rails']['gitlab_default_projects_limit'] = 10
default['gitlab']['gitlab-rails']['gitlab_default_can_create_group'] = true
default['gitlab']['gitlab-rails']['gitlab_username_changing_enabled'] = true
default['gitlab']['gitlab-rails']['gitlab_default_theme'] = 2
default['gitlab']['gitlab-rails']['gitlab_signup_enabled'] = false
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_issues'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_merge_requests'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wiki'] = true
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wall'] = false
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_snippets'] = false
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_visibility_level'] = "private"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_title'] = "Redmine"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_project_url'] = "http://redmine.sample/projects/:issues_tracker_id"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_issues_url'] = "http://redmine.sample/issues/:id"
default['gitlab']['gitlab-rails']['issues_tracker_redmine_new_issue_url'] = "http://redmine.sample/projects/:issues_tracker_id/issues/new"
default['gitlab']['gitlab-rails']['issues_tracker_jira_title'] = "Atlassian Jira"
default['gitlab']['gitlab-rails']['issues_tracker_jira_project_url'] = "http://jira.sample/issues/?jql=project=:issues_tracker_id"
default['gitlab']['gitlab-rails']['issues_tracker_jira_issues_url'] = "http://jira.sample/browse/:id"
default['gitlab']['gitlab-rails']['issues_tracker_jira_new_issue_url'] = "http://jira.sample/secure/CreateIssue.jspa"
default['gitlab']['gitlab-rails']['gravatar_enabled'] = true
default['gitlab']['gitlab-rails']['gravatar_plain_url'] = "http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm"
default['gitlab']['gitlab-rails']['gravatar_ssl_url'] = "https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm"
default['gitlab']['gitlab-rails']['ldap_enabled'] = false
default['gitlab']['gitlab-rails']['ldap_host'] = "_your_ldap_server"
default['gitlab']['gitlab-rails']['ldap_base'] = "_the_base_where_you_search_for_users"
default['gitlab']['gitlab-rails']['ldap_port'] = 636
default['gitlab']['gitlab-rails']['ldap_uid'] = "sAMAccountName"
default['gitlab']['gitlab-rails']['ldap_method'] = "ssl"
default['gitlab']['gitlab-rails']['ldap_bind_dn'] = "_the_full_dn_of_the_user_you_will_bind_with"
default['gitlab']['gitlab-rails']['ldap_password'] = "_the_password_of_the_bind_user"
default['gitlab']['gitlab-rails']['ldap_allow_username_or_email_login'] = true
default['gitlab']['gitlab-rails']['satellites_path'] = "/var/opt/gitlab/gitlab-satellites"
default['gitlab']['gitlab-rails']['backup_path'] = "tmp/backups"
default['gitlab']['gitlab-rails']['gitlab_shell_path'] = "/home/git/gitlab-shell/"
default['gitlab']['gitlab-rails']['gitlab_shell_repos_path'] = "/home/git/repositories/"
default['gitlab']['gitlab-rails']['gitlab_shell_hooks_path'] = "/home/git/gitlab-shell/hooks/"
default['gitlab']['gitlab-rails']['gitlab_shell_upload_pack'] = true
default['gitlab']['gitlab-rails']['gitlab_shell_receive_pack'] = true
default['gitlab']['gitlab-rails']['git_bin_path'] = "/usr/bin/git"
default['gitlab']['gitlab-rails']['git_max_size'] = 5242880
default['gitlab']['gitlab-rails']['git_timeout'] = 10
default['gitlab']['gitlab-rails']['extra'] =


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
