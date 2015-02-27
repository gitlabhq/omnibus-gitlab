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
default['gitlab']['omnibus-gitconfig']['system'] = {
  "receive" => ["fsckObjects = true"]
 }


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
default['gitlab']['gitlab-rails']['env'] = {
  'SIDEKIQ_MEMORY_KILLER_MAX_RSS' => '1000000',
  'BUNDLE_GEMFILE' => "/opt/gitlab/embedded/service/gitlab-rails/Gemfile",
  'PATH' => "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin"
}

default['gitlab']['gitlab-rails']['internal_api_url'] = nil
default['gitlab']['gitlab-rails']['uploads_directory'] = "/var/opt/gitlab/gitlab-rails/uploads"
default['gitlab']['gitlab-rails']['rate_limit_requests_per_period'] = 10
default['gitlab']['gitlab-rails']['rate_limit_period'] = 60

default['gitlab']['gitlab-rails']['gitlab_host'] = node['fqdn']
default['gitlab']['gitlab-rails']['gitlab_port'] = 80
default['gitlab']['gitlab-rails']['gitlab_https'] = false
default['gitlab']['gitlab-rails']['gitlab_ssh_host'] = nil
default['gitlab']['gitlab-rails']['time_zone'] = nil
default['gitlab']['gitlab-rails']['gitlab_email_from'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_limit'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_can_create_group'] = nil
default['gitlab']['gitlab-rails']['gitlab_username_changing_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_theme'] = nil
default['gitlab']['gitlab-rails']['gitlab_signup_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_signin_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_restricted_visibility_levels'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_issues'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_merge_requests'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wiki'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wall'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_snippets'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_visibility_level'] = nil
default['gitlab']['gitlab-rails']['gitlab_repository_downloads_path'] = nil
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
default['gitlab']['gitlab-rails']['ldap_servers'] = []

####
# These LDAP settings are deprecated in favor of the new syntax. They are kept here for backwards compatibility.
# Check
# https://gitlab.com/gitlab-org/omnibus-gitlab/blob/935ab9e1700bfe8db6ba084e3687658d8921716f/README.md#setting-up-ldap-sign-in
# for the new syntax.
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
default['gitlab']['gitlab-rails']['ldap_admin_group'] = nil
default['gitlab']['gitlab-rails']['ldap_sync_ssh_keys'] = nil
default['gitlab']['gitlab-rails']['ldap_sync_time'] = nil
default['gitlab']['gitlab-rails']['ldap_active_directory'] = nil
####

default['gitlab']['gitlab-rails']['omniauth_enabled'] = false
default['gitlab']['gitlab-rails']['omniauth_allow_single_sign_on'] = nil
default['gitlab']['gitlab-rails']['omniauth_block_auto_created_users'] = nil
default['gitlab']['gitlab-rails']['omniauth_providers'] = []
default['gitlab']['gitlab-rails']['satellites_path'] = "/var/opt/gitlab/git-data/gitlab-satellites"
default['gitlab']['gitlab-rails']['satellites_timeout'] = nil
default['gitlab']['gitlab-rails']['backup_path'] = "/var/opt/gitlab/backups"
default['gitlab']['gitlab-rails']['backup_keep_time'] = nil
default['gitlab']['gitlab-rails']['backup_upload_connection'] = nil
default['gitlab']['gitlab-rails']['backup_upload_remote_directory'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_path'] = "/opt/gitlab/embedded/service/gitlab-shell/"
default['gitlab']['gitlab-rails']['gitlab_shell_repos_path'] = "/var/opt/gitlab/git-data/repositories"
default['gitlab']['gitlab-rails']['gitlab_shell_hooks_path'] = "/opt/gitlab/embedded/service/gitlab-shell/hooks/"
default['gitlab']['gitlab-rails']['gitlab_shell_upload_pack'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_receive_pack'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_ssh_port'] = nil
default['gitlab']['gitlab-rails']['git_bin_path'] = "/opt/gitlab/embedded/bin/git"
default['gitlab']['gitlab-rails']['git_max_size'] = nil
default['gitlab']['gitlab-rails']['git_timeout'] = nil
default['gitlab']['gitlab-rails']['extra_google_analytics_id'] = nil
default['gitlab']['gitlab-rails']['extra_piwik_url'] = nil
default['gitlab']['gitlab-rails']['extra_piwik_site_id'] = nil
default['gitlab']['gitlab-rails']['extra_sign_in_text'] = nil

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
default['gitlab']['gitlab-rails']['db_password'] = nil
default['gitlab']['gitlab-rails']['db_host'] = nil
default['gitlab']['gitlab-rails']['db_port'] = 5432
default['gitlab']['gitlab-rails']['db_socket'] = nil

default['gitlab']['gitlab-rails']['redis_host'] = "127.0.0.1"
default['gitlab']['gitlab-rails']['redis_port'] = nil
default['gitlab']['gitlab-rails']['redis_socket'] = "/var/opt/gitlab/redis/redis.socket"

default['gitlab']['gitlab-rails']['smtp_enable'] = false
default['gitlab']['gitlab-rails']['smtp_address'] = nil
default['gitlab']['gitlab-rails']['smtp_port'] = nil
default['gitlab']['gitlab-rails']['smtp_user_name'] = nil
default['gitlab']['gitlab-rails']['smtp_password'] = nil
default['gitlab']['gitlab-rails']['smtp_domain'] = nil
default['gitlab']['gitlab-rails']['smtp_authentication'] = nil
default['gitlab']['gitlab-rails']['smtp_enable_starttls_auto'] = nil
default['gitlab']['gitlab-rails']['smtp_tls'] = nil
default['gitlab']['gitlab-rails']['smtp_openssl_verify_mode'] = nil

default['gitlab']['gitlab-rails']['webhook_timeout'] = nil

default['gitlab']['gitlab-rails']['initial_root_password'] = nil

####
# Unicorn
####
default['gitlab']['unicorn']['enable'] = true
default['gitlab']['unicorn']['ha'] = false
default['gitlab']['unicorn']['log_directory'] = "/var/log/gitlab/unicorn"
default['gitlab']['unicorn']['worker_processes'] = 2
default['gitlab']['unicorn']['listen'] = '127.0.0.1'
default['gitlab']['unicorn']['port'] = 8080
default['gitlab']['unicorn']['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
default['gitlab']['unicorn']['pidfile'] = '/opt/gitlab/var/unicorn/unicorn.pid'
default['gitlab']['unicorn']['tcp_nopush'] = true
default['gitlab']['unicorn']['backlog_socket'] = 1024
default['gitlab']['unicorn']['worker_timeout'] = 60

####
# Sidekiq
####
default['gitlab']['sidekiq']['enable'] = true
default['gitlab']['sidekiq']['ha'] = false
default['gitlab']['sidekiq']['log_directory'] = "/var/log/gitlab/sidekiq"
default['gitlab']['sidekiq']['shutdown_timeout'] = 4


###
# gitlab-shell
###
default['gitlab']['gitlab-shell']['log_directory'] = "/var/log/gitlab/gitlab-shell/"
default['gitlab']['gitlab-shell']['log_level'] = nil
default['gitlab']['gitlab-shell']['audit_usernames'] = nil
default['gitlab']['gitlab-shell']['git_data_directory'] = "/var/opt/gitlab/git-data"
default['gitlab']['gitlab-shell']['http_settings'] = nil
default['gitlab']['gitlab-shell']['git_annex_enabled'] = nil


###
# PostgreSQL
###
default['gitlab']['postgresql']['enable'] = true
default['gitlab']['postgresql']['ha'] = false
default['gitlab']['postgresql']['dir'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['data_dir'] = "/var/opt/gitlab/postgresql/data"
default['gitlab']['postgresql']['log_directory'] = "/var/log/gitlab/postgresql"
default['gitlab']['postgresql']['username'] = "gitlab-psql"
default['gitlab']['postgresql']['uid'] = nil
default['gitlab']['postgresql']['gid'] = nil
default['gitlab']['postgresql']['shell'] = "/bin/sh"
default['gitlab']['postgresql']['home'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['user_path'] = "/opt/gitlab/embedded/bin:/opt/gitlab/bin:$PATH"
default['gitlab']['postgresql']['sql_user'] = "gitlab"
default['gitlab']['postgresql']['sql_ci_user'] = "gitlab_ci"
default['gitlab']['postgresql']['port'] = 5432
default['gitlab']['postgresql']['listen_address'] = nil
default['gitlab']['postgresql']['max_connections'] = 200
default['gitlab']['postgresql']['md5_auth_cidr_addresses'] = []
default['gitlab']['postgresql']['trust_auth_cidr_addresses'] = []
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
default['gitlab']['redis']['username'] = "gitlab-redis"
default['gitlab']['redis']['uid'] = nil
default['gitlab']['redis']['gid'] = nil
default['gitlab']['redis']['shell'] = "/bin/nologin"
default['gitlab']['redis']['home'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['port'] = 0
default['gitlab']['redis']['unixsocket'] = "/var/opt/gitlab/redis/redis.socket"
default['gitlab']['redis']['unixsocketperm'] = "777"

####
# Web server
####
# Username for the webserver user
default['gitlab']['web-server']['username'] = 'gitlab-www'
default['gitlab']['web-server']['group'] = 'gitlab-www'
default['gitlab']['web-server']['uid'] = nil
default['gitlab']['web-server']['gid'] = nil
default['gitlab']['web-server']['shell'] = '/bin/false'
# When bundled nginx is disabled we need to add the external webserver user to the GitLab webserver group
default['gitlab']['web-server']['external_users'] = []

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
default['gitlab']['nginx']['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4"
default['gitlab']['nginx']['ssl_prefer_server_ciphers'] = "on"
default['gitlab']['nginx']['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
default['gitlab']['nginx']['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
default['gitlab']['nginx']['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
default['gitlab']['nginx']['listen_addresses'] = ['*']
default['gitlab']['nginx']['listen_port'] = nil # override only if you have a reverse proxy
default['gitlab']['nginx']['custom_gitlab_server_config'] = nil
default['gitlab']['nginx']['custom_nginx_config'] = nil

###
# Logging
###
default['gitlab']['logging']['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
default['gitlab']['logging']['svlogd_num'] = 30 # keep 30 rotated log files
default['gitlab']['logging']['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
default['gitlab']['logging']['svlogd_filter'] = "gzip" # compress logs with gzip
default['gitlab']['logging']['svlogd_udp'] = nil # transmit log messages via UDP
default['gitlab']['logging']['svlogd_prefix'] = nil # custom prefix for log messages
default['gitlab']['logging']['udp_log_shipping_host'] = nil # remote host to ship log messages to via UDP
default['gitlab']['logging']['udp_log_shipping_port'] = 514 # remote host to ship log messages to via UDP
default['gitlab']['logging']['logrotate_frequency'] = "daily" # rotate logs daily
default['gitlab']['logging']['logrotate_size'] = nil # do not rotate by size by default
default['gitlab']['logging']['logrotate_rotate'] = 30 # keep 30 rotated logs
default['gitlab']['logging']['logrotate_compress'] = "compress" # see 'man logrotate'
default['gitlab']['logging']['logrotate_method'] = "copytruncate" # see 'man logrotate'
default['gitlab']['logging']['logrotate_postrotate'] = nil # no postrotate command by default

###
# Remote syslog
###
default['gitlab']['remote-syslog']['enable'] = false
default['gitlab']['remote-syslog']['ha'] = false
default['gitlab']['remote-syslog']['dir'] = "/var/opt/gitlab/remote-syslog"
default['gitlab']['remote-syslog']['log_directory'] = "/var/log/gitlab/remote-syslog"
default['gitlab']['remote-syslog']['destination_host'] = "localhost"
default['gitlab']['remote-syslog']['destination_port'] = 514
default['gitlab']['remote-syslog']['services'] = %w{redis nginx unicorn gitlab-rails postgresql sidekiq}

###
# Logrotate
###
default['gitlab']['logrotate']['enable'] = true
default['gitlab']['logrotate']['ha'] = false
default['gitlab']['logrotate']['dir'] = "/var/opt/gitlab/logrotate"
default['gitlab']['logrotate']['log_directory'] = "/var/log/gitlab/logrotate"
default['gitlab']['logrotate']['services'] = %w{nginx unicorn gitlab-rails gitlab-shell gitlab-ci}
default['gitlab']['logrotate']['pre_sleep'] = 600 # sleep 10 minutes before rotating after start-up
default['gitlab']['logrotate']['post_sleep'] = 3000 # wait 50 minutes after rotating

###
# High Availability
###
default['gitlab']['high-availability']['mountpoint'] = nil

####
# GitLab CI Rails app
####
default['gitlab']['gitlab-ci']['enable'] = false
default['gitlab']['gitlab-ci']['dir'] = "/var/opt/gitlab/gitlab-ci"
default['gitlab']['gitlab-ci']['log_directory'] = "/var/log/gitlab/gitlab-ci"
default['gitlab']['gitlab-ci']['environment'] = 'production'
default['gitlab']['gitlab-ci']['env'] = {
  'BUNDLE_GEMFILE' => "/opt/gitlab/embedded/service/gitlab-ci/Gemfile",
  'PATH' => "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin"
}
default['gitlab']['gitlab-ci']['schedule_builds_minute'] = "0"

default['gitlab']['gitlab-ci']['username'] = "gitlab-ci"
default['gitlab']['gitlab-ci']['uid'] = nil
default['gitlab']['gitlab-ci']['gid'] = nil
default['gitlab']['gitlab-ci']['shell'] = "/bin/false"

# application.yml top-level settings
default['gitlab']['gitlab-ci']['gitlab_server'] = nil

# application.yml, gitlab_ci section
default['gitlab']['gitlab-ci']['gitlab_ci_host'] = node['fqdn']
default['gitlab']['gitlab-ci']['gitlab_ci_port'] = 80
default['gitlab']['gitlab-ci']['gitlab_ci_https'] = false
default['gitlab']['gitlab-ci']['gitlab_ci_email_from'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_support_email'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_all_broken_builds'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_add_committer'] = nil

# application.yml, gravatar section
default['gitlab']['gitlab-ci']['gravatar_enabled'] = true
default['gitlab']['gitlab-ci']['gravatar_plain_url'] = nil
default['gitlab']['gitlab-ci']['gravatar_ssl_url'] = nil

# database.yml settings
default['gitlab']['gitlab-ci']['db_adapter'] = "postgresql"
default['gitlab']['gitlab-ci']['db_encoding'] = "unicode"
default['gitlab']['gitlab-ci']['db_database'] = "gitlab_ci_production"
default['gitlab']['gitlab-ci']['db_pool'] = 10
default['gitlab']['gitlab-ci']['db_username'] = "gitlab_ci"
default['gitlab']['gitlab-ci']['db_password'] = nil
default['gitlab']['gitlab-ci']['db_host'] = nil
default['gitlab']['gitlab-ci']['db_port'] = 5432
default['gitlab']['gitlab-ci']['db_socket'] = nil

# resque.yml settings
default['gitlab']['gitlab-ci']['redis_host'] = "127.0.0.1"
default['gitlab']['gitlab-ci']['redis_port'] = nil
default['gitlab']['gitlab-ci']['redis_socket'] = "/var/opt/gitlab/ci-redis/redis.socket"

# config/initializers/smtp_settings.rb settings
default['gitlab']['gitlab-ci']['smtp_enable'] = false
default['gitlab']['gitlab-ci']['smtp_address'] = nil
default['gitlab']['gitlab-ci']['smtp_port'] = nil
default['gitlab']['gitlab-ci']['smtp_user_name'] = nil
default['gitlab']['gitlab-ci']['smtp_password'] = nil
default['gitlab']['gitlab-ci']['smtp_domain'] = nil
default['gitlab']['gitlab-ci']['smtp_authentication'] = nil
default['gitlab']['gitlab-ci']['smtp_enable_starttls_auto'] = nil
default['gitlab']['gitlab-ci']['smtp_tls'] = nil
default['gitlab']['gitlab-ci']['smtp_openssl_verify_mode'] = nil

####
# CI Unicorn
####
default['gitlab']['ci-unicorn'] = default['gitlab']['unicorn'].dup
default['gitlab']['ci-unicorn']['enable'] = false
default['gitlab']['ci-unicorn']['log_directory'] = "/var/log/gitlab/ci-unicorn"
default['gitlab']['ci-unicorn']['port'] = 8181
default['gitlab']['ci-unicorn']['socket'] = '/var/opt/gitlab/gitlab-ci/sockets/gitlab.socket'
default['gitlab']['ci-unicorn']['pidfile'] = '/opt/gitlab/var/ci-unicorn/unicorn.pid'

####
# CI Sidekiq
####
default['gitlab']['ci-sidekiq'] = default['gitlab']['sidekiq'].dup
default['gitlab']['ci-sidekiq']['enable'] = false
default['gitlab']['ci-sidekiq']['log_directory'] = "/var/log/gitlab/ci-sidekiq"

####
# CI Redis
####
default['gitlab']['ci-redis'] = default['gitlab']['redis'].dup
default['gitlab']['ci-redis']['enable'] = false
default['gitlab']['ci-redis']['dir'] = "/var/opt/gitlab/ci-redis"
default['gitlab']['ci-redis']['log_directory'] = "/var/log/gitlab/ci-redis"
default['gitlab']['ci-redis']['unixsocket'] = "/var/opt/gitlab/ci-redis/redis.socket"

####
# CI NGINX
####
default['gitlab']['ci-nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['ci-nginx']['enable'] = false
