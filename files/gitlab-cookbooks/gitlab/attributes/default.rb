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
  "pack" => ["threads = 1"],
  "receive" => ["fsckObjects = true"],
  "repack" => ["writeBitmaps = true"],
 }
# Create users and groups needed for the package
default['gitlab']['manage-accounts']['enable'] = true

# Create directories with correct permissions and ownership required by the pkg
default['gitlab']['manage-storage-directories']['enable'] = true
default['gitlab']['manage-storage-directories']['manage_etc'] = true

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
default['gitlab']['gitlab-rails']['enable'] = true
default['gitlab']['gitlab-rails']['dir'] = "/var/opt/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['log_directory'] = "/var/log/gitlab/gitlab-rails"
default['gitlab']['gitlab-rails']['environment'] = 'production'
default['gitlab']['gitlab-rails']['env'] = {
  'SIDEKIQ_MEMORY_KILLER_MAX_RSS' => '1000000',
  # Path to the Gemfile
  # defaults to /opt/gitlab/embedded/service/gitlab-rails/Gemfile. The install-dir path is set at build time
  'BUNDLE_GEMFILE' => "#{node['package']['install-dir']}/embedded/service/gitlab-rails/Gemfile",
  # PATH to set on the environment
  # defaults to /opt/gitlab/embedded/bin:/bin:/usr/bin. The install-dir path is set at build time
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin",
  # Charlock Holmes and libicu will report U_FILE_ACCESS_ERROR if this is not set to the right path
  # See https://gitlab.com/gitlab-org/gitlab-ce/issues/17415#note_13868167
  'ICU_DATA' => "#{node['package']['install-dir']}/embedded/share/icu/current",
  'PYTHONPATH' => "#{node['package']['install-dir']}/embedded/lib/python3.4/site-packages"
}
default['gitlab']['gitlab-rails']['enable_jemalloc'] = true

default['gitlab']['gitlab-rails']['internal_api_url'] = nil
default['gitlab']['gitlab-rails']['uploads_directory'] = "/var/opt/gitlab/gitlab-rails/uploads"
default['gitlab']['gitlab-rails']['rate_limit_requests_per_period'] = 10
default['gitlab']['gitlab-rails']['rate_limit_period'] = 60
default['gitlab']['gitlab-rails']['auto_migrate'] = true

default['gitlab']['gitlab-rails']['gitlab_host'] = node['fqdn']
default['gitlab']['gitlab-rails']['gitlab_port'] = 80
default['gitlab']['gitlab-rails']['gitlab_https'] = false
default['gitlab']['gitlab-rails']['gitlab_ssh_host'] = nil
default['gitlab']['gitlab-rails']['time_zone'] = nil
default['gitlab']['gitlab-rails']['gitlab_email_from'] = nil
default['gitlab']['gitlab-rails']['gitlab_email_display_name'] = nil
default['gitlab']['gitlab-rails']['gitlab_email_subject_suffix'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_can_create_group'] = nil
default['gitlab']['gitlab-rails']['gitlab_username_changing_enabled'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_theme'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_issues'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_merge_requests'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wiki'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_wall'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_snippets'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_builds'] = nil
default['gitlab']['gitlab-rails']['gitlab_default_projects_features_container_registry'] = nil
default['gitlab']['gitlab-rails']['gitlab_issue_closing_pattern'] = nil
default['gitlab']['gitlab-rails']['gitlab_repository_downloads_path'] = nil
default['gitlab']['gitlab-rails']['gravatar_plain_url'] = nil
default['gitlab']['gitlab-rails']['gravatar_ssl_url'] = nil
default['gitlab']['gitlab-rails']['stuck_ci_builds_worker_cron'] = nil
default['gitlab']['gitlab-rails']['expire_build_artifacts_worker_cron'] = nil
default['gitlab']['gitlab-rails']['repository_check_worker_cron'] = nil
default['gitlab']['gitlab-rails']['admin_email_worker_cron'] = nil
default['gitlab']['gitlab-rails']['repository_archive_cache_worker_cron'] = nil
default['gitlab']['gitlab-rails']['historical_data_worker_cron'] = nil
default['gitlab']['gitlab-rails']['update_all_mirrors_worker_cron'] = nil
default['gitlab']['gitlab-rails']['update_all_remote_mirrors_worker_cron'] = nil
default['gitlab']['gitlab-rails']['ldap_sync_worker_cron'] = nil
default['gitlab']['gitlab-rails']['geo_bulk_notify_worker_cron'] = nil
default['gitlab']['gitlab-rails']['incoming_email_enabled'] = false
default['gitlab']['gitlab-rails']['incoming_email_address'] = nil
default['gitlab']['gitlab-rails']['incoming_email_host'] = nil
default['gitlab']['gitlab-rails']['incoming_email_port'] = nil
default['gitlab']['gitlab-rails']['incoming_email_ssl'] = nil
default['gitlab']['gitlab-rails']['incoming_email_start_tls'] = nil
default['gitlab']['gitlab-rails']['incoming_email_email'] = nil
default['gitlab']['gitlab-rails']['incoming_email_password'] = nil
default['gitlab']['gitlab-rails']['incoming_email_mailbox_name'] = "inbox"
default['gitlab']['gitlab-rails']['incoming_email_idle_timeout'] = nil
default['gitlab']['gitlab-rails']['artifacts_enabled'] = true
default['gitlab']['gitlab-rails']['artifacts_path'] = nil
default['gitlab']['gitlab-rails']['lfs_enabled'] = nil
default['gitlab']['gitlab-rails']['lfs_storage_path'] = nil
default['gitlab']['gitlab-rails']['elasticsearch_enabled'] = false
default['gitlab']['gitlab-rails']['elasticsearch_host'] = nil
default['gitlab']['gitlab-rails']['elasticsearch_port'] = nil
default['gitlab']['gitlab-rails']['ldap_enabled'] = false
default['gitlab']['gitlab-rails']['ldap_servers'] = []
default['gitlab']['gitlab-rails']['pages_enabled'] = false
default['gitlab']['gitlab-rails']['pages_host'] = nil
default['gitlab']['gitlab-rails']['pages_port'] = nil
default['gitlab']['gitlab-rails']['pages_https'] = false
default['gitlab']['gitlab-rails']['pages_path'] = nil
default['gitlab']['gitlab-rails']['registry_enabled'] = false
default['gitlab']['gitlab-rails']['registry_host'] = nil
default['gitlab']['gitlab-rails']['registry_port'] = nil
default['gitlab']['gitlab-rails']['registry_api_url'] = nil
default['gitlab']['gitlab-rails']['registry_key_path'] = nil
default['gitlab']['gitlab-rails']['registry_path'] = nil
default['gitlab']['gitlab-rails']['registry_issuer'] = "omnibus-gitlab-issuer"

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

default['gitlab']['gitlab-rails']['kerberos_enabled'] = nil
default['gitlab']['gitlab-rails']['kerberos_keytab'] = nil
default['gitlab']['gitlab-rails']['kerberos_service_principal_name'] = nil
default['gitlab']['gitlab-rails']['kerberos_use_dedicated_port'] = nil
default['gitlab']['gitlab-rails']['kerberos_port'] = nil
default['gitlab']['gitlab-rails']['kerberos_https'] = nil

default['gitlab']['gitlab-rails']['omniauth_enabled'] = false
default['gitlab']['gitlab-rails']['omniauth_allow_single_sign_on'] = ['saml']
default['gitlab']['gitlab-rails']['omniauth_auto_sign_in_with_provider'] = nil
default['gitlab']['gitlab-rails']['omniauth_block_auto_created_users'] = nil
default['gitlab']['gitlab-rails']['omniauth_auto_link_ldap_user'] = nil
default['gitlab']['gitlab-rails']['omniauth_auto_link_saml_user'] = nil
default['gitlab']['gitlab-rails']['omniauth_external_providers'] = nil
default['gitlab']['gitlab-rails']['omniauth_providers'] = []
default['gitlab']['gitlab-rails']['bitbucket'] = nil

default['gitlab']['gitlab-rails']['shared_path'] = "/var/opt/gitlab/gitlab-rails/shared"

# Important: keep the satellites.path setting until GitLab 9.0 at
# least. This setting is fed to 'rm -rf' in
# db/migrate/20151023144219_remove_satellites.rb
default['gitlab']['gitlab-rails']['satellites_path'] = "/var/opt/gitlab/git-data/gitlab-satellites"
default['gitlab']['gitlab-rails']['satellites_timeout'] = nil
#

default['gitlab']['gitlab-rails']['backup_path'] = "/var/opt/gitlab/backups"
default['gitlab']['gitlab-rails']['manage_backup_path'] = true
default['gitlab']['gitlab-rails']['backup_archive_permissions'] = nil
default['gitlab']['gitlab-rails']['backup_pg_schema'] = nil
default['gitlab']['gitlab-rails']['backup_keep_time'] = nil
default['gitlab']['gitlab-rails']['backup_upload_connection'] = nil
default['gitlab']['gitlab-rails']['backup_upload_remote_directory'] = nil
default['gitlab']['gitlab-rails']['backup_multipart_chunk_size'] = nil
default['gitlab']['gitlab-rails']['backup_encryption'] = nil
# Path to the GitLab Shell installation
# defaults to /opt/gitlab/embedded/service/gitlab-shell/. The install-dir path is set at build time
default['gitlab']['gitlab-rails']['gitlab_shell_path'] = "#{node['package']['install-dir']}/embedded/service/gitlab-shell/"
# Path to the git hooks used by GitLab Shell
# defaults to /opt/gitlab/embedded/service/gitlab-shell/hooks/. The install-dir path is set at build time
default['gitlab']['gitlab-rails']['gitlab_shell_hooks_path'] = "#{node['package']['install-dir']}/embedded/service/gitlab-shell/hooks/"
default['gitlab']['gitlab-rails']['gitlab_shell_upload_pack'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_receive_pack'] = nil
default['gitlab']['gitlab-rails']['gitlab_shell_ssh_port'] = nil
# Path to the Git Executable
# defaults to /opt/gitlab/embedded/bin/git. The install-dir path is set at build time
default['gitlab']['gitlab-rails']['git_bin_path'] = "#{node['package']['install-dir']}/embedded/bin/git"
default['gitlab']['gitlab-rails']['git_max_size'] = nil
default['gitlab']['gitlab-rails']['git_timeout'] = nil
default['gitlab']['gitlab-rails']['extra_google_analytics_id'] = nil
default['gitlab']['gitlab-rails']['extra_piwik_url'] = nil
default['gitlab']['gitlab-rails']['extra_piwik_site_id'] = nil
default['gitlab']['gitlab-rails']['rack_attack_git_basic_auth'] = nil
default['gitlab']['gitlab-rails']['rack_attack_protected_paths'] = [
  '/users/password',
  '/users/sign_in',
  '/api/#{API::API.version}/session.json',
  '/api/#{API::API.version}/session',
  '/users',
  '/users/confirmation',
  '/unsubscribes/',
  '/import/github/personal_access_token'
]
default['gitlab']['gitlab-rails']['aws_enable'] = false
default['gitlab']['gitlab-rails']['aws_access_key_id'] = nil
default['gitlab']['gitlab-rails']['aws_secret_access_key'] = nil
default['gitlab']['gitlab-rails']['aws_bucket'] = nil
default['gitlab']['gitlab-rails']['aws_region'] = nil

default['gitlab']['gitlab-rails']['db_adapter'] = "postgresql"
default['gitlab']['gitlab-rails']['db_encoding'] = "unicode"
default['gitlab']['gitlab-rails']['db_collation'] = nil
default['gitlab']['gitlab-rails']['db_database'] = "gitlabhq_production"
default['gitlab']['gitlab-rails']['db_pool'] = 10
default['gitlab']['gitlab-rails']['db_username'] = "gitlab"
default['gitlab']['gitlab-rails']['db_password'] = nil
# Path to postgresql socket directory
default['gitlab']['gitlab-rails']['db_host'] = "/var/opt/gitlab/postgresql"
default['gitlab']['gitlab-rails']['db_port'] = 5432
default['gitlab']['gitlab-rails']['db_socket'] = nil
default['gitlab']['gitlab-rails']['db_sslmode'] = nil
default['gitlab']['gitlab-rails']['db_sslrootcert'] = nil
default['gitlab']['gitlab-rails']['db_sslca'] = nil

default['gitlab']['gitlab-rails']['redis_host'] = "127.0.0.1"
default['gitlab']['gitlab-rails']['redis_port'] = nil
default['gitlab']['gitlab-rails']['redis_password'] = nil
default['gitlab']['gitlab-rails']['redis_socket'] = "/var/opt/gitlab/redis/redis.socket"
default['gitlab']['gitlab-rails']['redis_sentinels'] = []

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
default['gitlab']['gitlab-rails']['smtp_ca_path'] = nil
# Path to the public Certificate Authority file
# defaults to /opt/gitlab/embedded/ssl/certs/cacert.pem. The install-dir path is set at build time
default['gitlab']['gitlab-rails']['smtp_ca_file'] = "#{node['package']['install-dir']}/embedded/ssl/certs/cacert.pem"

# Path to directory that contains (ca) certificates that should also be trusted (e.g. on
# outgoing Webhooks connections). For these certificates symlinks will be created in
# /opt/gitlab/embedded/ssl/certs/.
default['gitlab']['gitlab-rails']['trusted_certs_dir'] = "/etc/gitlab/trusted-certs"

default['gitlab']['gitlab-rails']['webhook_timeout'] = nil

default['gitlab']['gitlab-rails']['initial_root_password'] = nil
default['gitlab']['gitlab-rails']['trusted_proxies'] = nil

####
# Unicorn
####
default['gitlab']['unicorn']['enable'] = true
default['gitlab']['unicorn']['ha'] = false
default['gitlab']['unicorn']['log_directory'] = "/var/log/gitlab/unicorn"
default['gitlab']['unicorn']['worker_processes'] = [
  2, # Two is the minimum or web editor will no longer work.
  [
    # Cores + 1 gives good CPU utilization.
    node['cpu']['total'].to_i + 1,
    # See how many 300MB worker processes fit in (total RAM - 1GB). We add
    # 128000 KB in the numerator to get rounding instead of integer truncation.
    (node['memory']['total'].to_i - 1048576 + 128000) / 358400
  ].min # min because we want to exceed neither CPU nor RAM
].max # max because we need at least 2 workers
default['gitlab']['unicorn']['listen'] = '127.0.0.1'
default['gitlab']['unicorn']['port'] = 8080
default['gitlab']['unicorn']['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
# Path to the unicorn server Process ID file
# defaults to /opt/gitlab/var/unicorn/unicorn.pid. The install-dir path is set at build time
default['gitlab']['unicorn']['pidfile'] = "#{node['package']['install-dir']}/var/unicorn/unicorn.pid"
default['gitlab']['unicorn']['tcp_nopush'] = true
default['gitlab']['unicorn']['backlog_socket'] = 1024
default['gitlab']['unicorn']['somaxconn'] = 1024
default['gitlab']['unicorn']['worker_timeout'] = 60
default['gitlab']['unicorn']['worker_memory_limit_min'] = "400 * 1 << 20"
default['gitlab']['unicorn']['worker_memory_limit_max'] = "650 * 1 << 20"

####
# Sidekiq
####
default['gitlab']['sidekiq']['enable'] = true
default['gitlab']['sidekiq']['ha'] = false
default['gitlab']['sidekiq']['log_directory'] = "/var/log/gitlab/sidekiq"
default['gitlab']['sidekiq']['shutdown_timeout'] = 4
default['gitlab']['sidekiq']['concurrency'] = 25


###
# gitlab-shell
###
default['gitlab']['gitlab-shell']['log_directory'] = "/var/log/gitlab/gitlab-shell/"
default['gitlab']['gitlab-shell']['log_level'] = nil
default['gitlab']['gitlab-shell']['audit_usernames'] = nil
default['gitlab']['gitlab-shell']['git_data_directories'] = {
  "default" => "/var/opt/gitlab/git-data"
}
default['gitlab']['gitlab-rails']['repositories_storages'] = {
  "default" => "/var/opt/gitlab/git-data/repositories"
}
default['gitlab']['gitlab-shell']['http_settings'] = nil
default['gitlab']['gitlab-shell']['git_annex_enabled'] = nil
default['gitlab']['gitlab-shell']['auth_file'] = nil
default['gitlab']['gitlab-shell']['git_trace_log_file'] = nil


###
# PostgreSQL
###
default['gitlab']['postgresql']['enable'] = true
default['gitlab']['postgresql']['ha'] = false
default['gitlab']['postgresql']['dir'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['data_dir'] = "/var/opt/gitlab/postgresql/data"
default['gitlab']['postgresql']['log_directory'] = "/var/log/gitlab/postgresql"
default['gitlab']['postgresql']['unix_socket_directory'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['username'] = "gitlab-psql"
default['gitlab']['postgresql']['uid'] = nil
default['gitlab']['postgresql']['gid'] = nil
default['gitlab']['postgresql']['shell'] = "/bin/sh"
default['gitlab']['postgresql']['home'] = "/var/opt/gitlab/postgresql"
# Postgres User's Environment Path
# defaults to /opt/gitlab/embedded/bin:/opt/gitlab/bin/$PATH. The install-dir path is set at build time
default['gitlab']['postgresql']['user_path'] = "#{node['package']['install-dir']}/embedded/bin:#{node['package']['install-dir']}/bin:$PATH"
default['gitlab']['postgresql']['sql_user'] = "gitlab"
default['gitlab']['postgresql']['sql_ci_user'] = "gitlab_ci"
default['gitlab']['postgresql']['sql_mattermost_user'] = "gitlab_mattermost"
default['gitlab']['postgresql']['port'] = 5432
# Postgres allow multi listen_address, comma-separated values.
# If used, first address from the list will be use for connection
default['gitlab']['postgresql']['listen_address'] = nil
default['gitlab']['postgresql']['max_connections'] = 200
default['gitlab']['postgresql']['md5_auth_cidr_addresses'] = []
default['gitlab']['postgresql']['trust_auth_cidr_addresses'] = []
default['gitlab']['postgresql']['shmmax'] = node['kernel']['machine'] =~ /x86_64/ ? 17179869184 : 4294967295
default['gitlab']['postgresql']['shmall'] = node['kernel']['machine'] =~ /x86_64/ ? 4194304 : 1048575
default['gitlab']['postgresql']['semmsl'] = 250
default['gitlab']['postgresql']['semmns'] = 32000
default['gitlab']['postgresql']['semopm'] = 32
default['gitlab']['postgresql']['semmni'] = ((node['gitlab']['postgresql']['max_connections'].to_i / 16) + 250)

# Resolves CHEF-3889
if (node['memory']['total'].to_i / 4) > ((node['gitlab']['postgresql']['shmmax'].to_i / 1024) - 2097152)
  # guard against setting shared_buffers > shmmax on hosts with installed RAM > 64GB
  # use 2GB less than shmmax as the default for these large memory machines
  default['gitlab']['postgresql']['shared_buffers'] = "14336MB"
else
  default['gitlab']['postgresql']['shared_buffers'] = "#{(node['memory']['total'].to_i / 4) / (1024)}MB"
end

default['gitlab']['postgresql']['work_mem'] = "8MB"
default['gitlab']['postgresql']['maintenance_work_mem'] = "16MB"
default['gitlab']['postgresql']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / (1024)}MB"
default['gitlab']['postgresql']['log_min_duration_statement'] = -1 # Disable slow query logging by default
default['gitlab']['postgresql']['checkpoint_segments'] = 10
default['gitlab']['postgresql']['min_wal_size'] = '80MB'
default['gitlab']['postgresql']['max_wal_size'] = '1GB'
default['gitlab']['postgresql']['checkpoint_timeout'] = "5min"
default['gitlab']['postgresql']['checkpoint_completion_target'] = 0.9
default['gitlab']['postgresql']['checkpoint_warning'] = "30s"
default['gitlab']['postgresql']['wal_buffers'] = "-1"
default['gitlab']['postgresql']['autovacuum'] = "on"
default['gitlab']['postgresql']['log_autovacuum_min_duration'] = "-1"
default['gitlab']['postgresql']['autovacuum_max_workers'] = "3"
default['gitlab']['postgresql']['autovacuum_naptime'] = "1min"
default['gitlab']['postgresql']['autovacuum_vacuum_threshold'] = "50"
default['gitlab']['postgresql']['autovacuum_analyze_threshold'] = "50"
default['gitlab']['postgresql']['autovacuum_vacuum_scale_factor'] = "0.02" # 10x lower than PG defaults
default['gitlab']['postgresql']['autovacuum_analyze_scale_factor'] = "0.01" # 10x lower than PG defaults
default['gitlab']['postgresql']['autovacuum_freeze_max_age'] = "200000000"
default['gitlab']['postgresql']['autovacuum_vacuum_cost_delay'] = "20ms"
default['gitlab']['postgresql']['autovacuum_vacuum_cost_limit'] = "-1"
default['gitlab']['postgresql']['statement_timeout'] = "0"
default['gitlab']['postgresql']['log_line_prefix'] = nil
default['gitlab']['postgresql']['track_activity_query_size'] = "1024"
default['gitlab']['postgresql']['shared_preload_libraries'] = nil

# Replication settings
default['gitlab']['postgresql']['sql_replication_user'] = "gitlab_replicator"
default['gitlab']['postgresql']['wal_level'] = "minimal"
default['gitlab']['postgresql']['max_wal_senders'] = 0
default['gitlab']['postgresql']['wal_keep_segments'] = 10
default['gitlab']['postgresql']['hot_standby'] = "off"

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
default['gitlab']['redis']['shell'] = "/bin/false"
default['gitlab']['redis']['home'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['bind'] = '127.0.0.1'
default['gitlab']['redis']['port'] = 0
default['gitlab']['redis']['maxclients'] = "10000"
default['gitlab']['redis']['tcp_timeout'] = 60
default['gitlab']['redis']['tcp_keepalive'] = 300
default['gitlab']['redis']['password'] = nil
default['gitlab']['redis']['unixsocket'] = "/var/opt/gitlab/redis/redis.socket"
default['gitlab']['redis']['unixsocketperm'] = "777"
default['gitlab']['redis']['master'] = true
default['gitlab']['redis']['master_name'] = 'gitlab-redis'
default['gitlab']['redis']['master_ip'] = nil
default['gitlab']['redis']['master_port'] = 6379
default['gitlab']['redis']['master_password'] = nil

####
# Web server
####
# Username for the webserver user
default['gitlab']['web-server']['username'] = 'gitlab-www'
default['gitlab']['web-server']['group'] = 'gitlab-www'
default['gitlab']['web-server']['uid'] = nil
default['gitlab']['web-server']['gid'] = nil
default['gitlab']['web-server']['shell'] = '/bin/false'
default['gitlab']['web-server']['home'] = '/var/opt/gitlab/nginx'
# When bundled nginx is disabled we need to add the external webserver user to the GitLab webserver group
default['gitlab']['web-server']['external_users'] = []

####
# gitlab-workhorse
####

default['gitlab']['gitlab-workhorse']['enable'] = true
default['gitlab']['gitlab-workhorse']['ha'] = false
default['gitlab']['gitlab-workhorse']['listen_network'] = "unix"
default['gitlab']['gitlab-workhorse']['listen_umask'] = 000
default['gitlab']['gitlab-workhorse']['listen_addr'] = "/var/opt/gitlab/gitlab-workhorse/socket"
default['gitlab']['gitlab-workhorse']['auth_backend'] = "http://localhost:8080"
default['gitlab']['gitlab-workhorse']['auth_socket'] = "''" # the empty string is the default in gitlab-workhorse option parser
default['gitlab']['gitlab-workhorse']['pprof_listen_addr'] = "''" # put an empty string on the command line
default['gitlab']['gitlab-workhorse']['dir'] = "/var/opt/gitlab/gitlab-workhorse"
default['gitlab']['gitlab-workhorse']['log_directory'] = "/var/log/gitlab/gitlab-workhorse"
default['gitlab']['gitlab-workhorse']['proxy_headers_timeout'] = nil
default['gitlab']['gitlab-workhorse']['api_limit'] = nil
default['gitlab']['gitlab-workhorse']['api_queue_duration'] = nil
default['gitlab']['gitlab-workhorse']['api_queue_limit'] = nil
default['gitlab']['gitlab-workhorse']['env'] = {
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin",
  'HOME' => node['gitlab']['user']['home']
}

####
# mailroom
####

default['gitlab']['mailroom']['enable'] = false
default['gitlab']['mailroom']['ha'] = false
default['gitlab']['mailroom']['log_directory'] = "/var/log/gitlab/mailroom"

####
# GitLab Pages Daemon
####
default['gitlab']['gitlab-pages']['enable'] = false
default['gitlab']['gitlab-pages']['external_http'] = nil
default['gitlab']['gitlab-pages']['external_https'] = nil
default['gitlab']['gitlab-pages']['listen_proxy'] = "localhost:8090"
default['gitlab']['gitlab-pages']['pages_path'] = nil
default['gitlab']['gitlab-pages']['domain'] = nil
default['gitlab']['gitlab-pages']['cert'] = nil
default['gitlab']['gitlab-pages']['cert_key'] = nil
default['gitlab']['gitlab-pages']['redirect_http'] = true
default['gitlab']['gitlab-pages']['use_http2'] = true
default['gitlab']['gitlab-pages']['dir'] = "/var/opt/gitlab/gitlab-pages"
default['gitlab']['gitlab-pages']['log_directory'] = "/var/log/gitlab/gitlab-pages"

####
# Registry
####
default['gitlab']['registry']['enable'] = false
default['gitlab']['registry']['username'] = "registry"
default['gitlab']['registry']['group'] = "registry"
default['gitlab']['registry']['uid'] = nil
default['gitlab']['registry']['gid'] = nil
default['gitlab']['registry']['dir'] = "/var/opt/gitlab/registry"
default['gitlab']['registry']['log_directory'] = "/var/log/gitlab/registry"
default['gitlab']['registry']['log_level'] = "info"
default['gitlab']['registry']['rootcertbundle'] = nil
default['gitlab']['registry']['storage_delete_enabled'] = nil
default['gitlab']['registry']['storage'] = nil
default['gitlab']['registry']['debug_addr'] = nil

####
# Nginx
####
default['gitlab']['nginx']['enable'] = true
default['gitlab']['nginx']['ha'] = false
default['gitlab']['nginx']['dir'] = "/var/opt/gitlab/nginx"
default['gitlab']['nginx']['log_directory'] = "/var/log/gitlab/nginx"
default['gitlab']['nginx']['worker_processes'] = node['cpu']['total'].to_i
default['gitlab']['nginx']['worker_connections'] = 10240
default['gitlab']['nginx']['log_format'] = '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"' #  NGINX 'combined' format
default['gitlab']['nginx']['sendfile'] = 'on'
default['gitlab']['nginx']['tcp_nopush'] = 'on'
default['gitlab']['nginx']['tcp_nodelay'] = 'on'
default['gitlab']['nginx']['gzip'] = "on"
default['gitlab']['nginx']['gzip_http_version'] = "1.0"
default['gitlab']['nginx']['gzip_comp_level'] = "2"
default['gitlab']['nginx']['gzip_proxied'] = "any"
default['gitlab']['nginx']['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
default['gitlab']['nginx']['keepalive_timeout'] = 65
default['gitlab']['nginx']['client_max_body_size'] = 0
default['gitlab']['nginx']['cache_max_size'] = '5000m'
default['gitlab']['nginx']['redirect_http_to_https'] = false
default['gitlab']['nginx']['redirect_http_to_https_port'] = 80
default['gitlab']['nginx']['ssl_client_certificate'] = nil # Most root CA's will be included by default
default['gitlab']['nginx']['ssl_verify_client'] = nil # do not enable 2-way SSL client authentication
default['gitlab']['nginx']['ssl_verify_depth'] = "1" # n/a if ssl_verify_client off
default['gitlab']['nginx']['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
default['gitlab']['nginx']['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
default['gitlab']['nginx']['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4"
default['gitlab']['nginx']['ssl_prefer_server_ciphers'] = "on"
default['gitlab']['nginx']['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
default['gitlab']['nginx']['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
default['gitlab']['nginx']['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
default['gitlab']['nginx']['ssl_dhparam'] = nil # Path to dhparam.pem
default['gitlab']['nginx']['listen_addresses'] = ['*', '[::]']
default['gitlab']['nginx']['listen_port'] = nil # override only if you have a reverse proxy
default['gitlab']['nginx']['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP
default['gitlab']['nginx']['custom_gitlab_server_config'] = nil
default['gitlab']['nginx']['custom_nginx_config'] = nil
default['gitlab']['nginx']['proxy_read_timeout'] = 3600
default['gitlab']['nginx']['proxy_connect_timeout'] = 300
default['gitlab']['nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for"
}
default['gitlab']['nginx']['http2_enabled'] = true
# Cache up to 1GB of HTTP responses from GitLab on disk
default['gitlab']['nginx']['proxy_cache_path'] = 'proxy_cache keys_zone=gitlab:10m max_size=1g levels=1:2'
# Set to 'off' to disable proxy caching.
default['gitlab']['nginx']['proxy_cache'] = 'gitlab'
# Config for the http_realip_module http://nginx.org/en/docs/http/ngx_http_realip_module.html
default['gitlab']['nginx']['real_ip_trusted_addresses'] = [] # Each entry creates a set_real_ip_from directive
default['gitlab']['nginx']['real_ip_header'] = nil
default['gitlab']['nginx']['real_ip_recursive'] = nil
default['gitlab']['nginx']['server_names_hash_bucket_size'] = 64

###
# Nginx status
###
default['gitlab']['nginx']['status']['enable'] = true
default['gitlab']['nginx']['status']['listen_addresses'] = ['*']
default['gitlab']['nginx']['status']['fqdn'] = "localhost"
default['gitlab']['nginx']['status']['port'] = 8060
default['gitlab']['nginx']['status']['options'] = {
  "stub_status" => "on",
  "server_tokens" => "off",
  "access_log" => "off",
  "allow" => "127.0.0.1",
  "deny" => "all",
}

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
default['gitlab']['logging']['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz

###
# Remote syslog
###
default['gitlab']['remote-syslog']['enable'] = false
default['gitlab']['remote-syslog']['ha'] = false
default['gitlab']['remote-syslog']['dir'] = "/var/opt/gitlab/remote-syslog"
default['gitlab']['remote-syslog']['log_directory'] = "/var/log/gitlab/remote-syslog"
default['gitlab']['remote-syslog']['destination_host'] = "localhost"
default['gitlab']['remote-syslog']['destination_port'] = 514
default['gitlab']['remote-syslog']['services'] = %w{redis nginx unicorn gitlab-rails gitlab-shell postgresql sidekiq gitlab-workhorse gitlab-pages}

###
# Logrotate
###
default['gitlab']['logrotate']['enable'] = true
default['gitlab']['logrotate']['ha'] = false
default['gitlab']['logrotate']['dir'] = "/var/opt/gitlab/logrotate"
default['gitlab']['logrotate']['log_directory'] = "/var/log/gitlab/logrotate"
default['gitlab']['logrotate']['services'] = %w{nginx unicorn gitlab-rails gitlab-shell gitlab-workhorse gitlab-pages}
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
default['gitlab']['gitlab-ci']['builds_directory'] = "/var/opt/gitlab/gitlab-ci/builds"
default['gitlab']['gitlab-ci']['environment'] = 'production'
default['gitlab']['gitlab-ci']['env'] = {
  # Path the the GitLab CI Gemfile
  # defaults to /opt/gitlab/embedded/service/gitlab-ci/Gemfile. The install-dir path is set at build time
  'BUNDLE_GEMFILE' => "#{node['package']['install-dir']}/embedded/service/gitlab-ci/Gemfile",
  # Path variable set in the environment for the GitLab CI processes
  # defaults to /opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin. The install-dir path is set at build time
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin"
}
default['gitlab']['gitlab-ci']['schedule_builds_minute'] = "0"

default['gitlab']['gitlab-ci']['username'] = "gitlab-ci"
default['gitlab']['gitlab-ci']['uid'] = nil
default['gitlab']['gitlab-ci']['gid'] = nil
default['gitlab']['gitlab-ci']['shell'] = "/bin/false"

# application.yml top-level settings
default['gitlab']['gitlab-ci']['gitlab_server'] = nil

# application.yml, gitlab_ci section
default['gitlab']['gitlab-ci']['gitlab_ci_host'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_port'] = 80
default['gitlab']['gitlab-ci']['gitlab_ci_https'] = false
default['gitlab']['gitlab-ci']['gitlab_ci_email_from'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_support_email'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_all_broken_builds'] = nil
default['gitlab']['gitlab-ci']['gitlab_ci_add_pusher'] = nil

default['gitlab']['gitlab-ci']['gitlab_ci_add_committer'] = nil # Deprecated, will be removed in the next release

# application.yml, gravatar section
default['gitlab']['gitlab-ci']['gravatar_enabled'] = true
default['gitlab']['gitlab-ci']['gravatar_plain_url'] = nil
default['gitlab']['gitlab-ci']['gravatar_ssl_url'] = nil

# application.yml, backup section
default['gitlab']['gitlab-ci']['backup_path'] = "/var/opt/gitlab/ci-backups"
default['gitlab']['gitlab-ci']['backup_keep_time'] = nil
default['gitlab']['gitlab-ci']['backup_upload_connection'] = nil
default['gitlab']['gitlab-ci']['backup_upload_remote_directory'] = nil
default['gitlab']['gitlab-ci']['backup_multipart_chunk_size'] = nil

# database.yml settings
default['gitlab']['gitlab-ci']['db_adapter'] = "postgresql"
default['gitlab']['gitlab-ci']['db_encoding'] = "unicode"
default['gitlab']['gitlab-ci']['db_database'] = "gitlab_ci_production"
default['gitlab']['gitlab-ci']['db_pool'] = 10
default['gitlab']['gitlab-ci']['db_username'] = "gitlab_ci"
default['gitlab']['gitlab-ci']['db_password'] = nil
# Path to postgresql socket directory
default['gitlab']['gitlab-ci']['db_host'] = "/var/opt/gitlab/postgresql"
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
# Path to the GitLab CI's Unicorn Process ID file
# defaults to /opt/gitlab/var/ci-unicorn/unicorn.pid. The install-dir path is set at build time
default['gitlab']['ci-unicorn']['pidfile'] = "#{node['package']['install-dir']}/var/ci-unicorn/unicorn.pid"

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
default['gitlab']['ci-nginx']['resolver'] = "8.8.8.8 8.8.4.4"

####
# Mattermost
####

default['gitlab']['mattermost']['enable'] = false
default['gitlab']['mattermost']['username'] = 'mattermost'
default['gitlab']['mattermost']['group'] = 'mattermost'
default['gitlab']['mattermost']['uid'] = nil
default['gitlab']['mattermost']['gid'] = nil
default['gitlab']['mattermost']['home'] = '/var/opt/gitlab/mattermost'
default['gitlab']['mattermost']['database_name'] = 'mattermost_production'

default['gitlab']['mattermost']['log_file_directory'] = '/var/log/gitlab/mattermost'
default['gitlab']['mattermost']['log_console_enable'] = true
default['gitlab']['mattermost']['log_enable_webhook_debugging'] = true
default['gitlab']['mattermost']['log_console_level'] = 'INFO'
default['gitlab']['mattermost']['log_enable_file'] = true
default['gitlab']['mattermost']['log_file_level'] = 'ERROR'
default['gitlab']['mattermost']['log_file_format'] = nil
default['gitlab']['mattermost']['log_enable_diagnostics'] = true

default['gitlab']['mattermost']['service_use_ssl'] = false
default['gitlab']['mattermost']['service_address'] = "127.0.0.1"
default['gitlab']['mattermost']['service_port'] = "8065"

default['gitlab']['mattermost']['service_site_url'] = nil
default['gitlab']['mattermost']['service_maximum_login_attempts'] = 10
default['gitlab']['mattermost']['service_segment_developer_key'] = nil
default['gitlab']['mattermost']['service_google_developer_key'] = nil
default['gitlab']['mattermost']['service_enable_incoming_webhooks'] = false
default['gitlab']['mattermost']['service_enable_post_username_override'] = false
default['gitlab']['mattermost']['service_enable_post_icon_override'] = false
default['gitlab']['mattermost']['service_enable_testing'] = false
default['gitlab']['mattermost']['service_enable_security_fix_alert'] = true
default['gitlab']['mattermost']['service_enable_insecure_outgoing_connections'] = false
default['gitlab']['mattermost']['service_allow_cors_from'] = nil
default['gitlab']['mattermost']['service_enable_outgoing_webhooks'] = false
default['gitlab']['mattermost']['service_enable_commands'] = false
default['gitlab']['mattermost']['service_enable_custom_emoji'] = false
default['gitlab']['mattermost']['service_enable_only_admin_integrations'] = true
default['gitlab']['mattermost']['service_enable_oauth_service_provider'] = false
default['gitlab']['mattermost']['service_enable_developer'] = false
default['gitlab']['mattermost']['service_session_length_web_in_days'] = 30
default['gitlab']['mattermost']['service_session_length_mobile_in_days'] = 30
default['gitlab']['mattermost']['service_session_length_sso_in_days'] = 30
default['gitlab']['mattermost']['service_session_cache_in_minutes'] = 10
default['gitlab']['mattermost']['service_connection_security'] = nil
default['gitlab']['mattermost']['service_tls_cert_file'] = nil
default['gitlab']['mattermost']['service_tls_key_file'] = nil
default['gitlab']['mattermost']['service_use_lets_encrypt'] = false
default['gitlab']['mattermost']['service_lets_encrypt_cert_cache_file'] = "./config/letsencrypt.cache"
default['gitlab']['mattermost']['service_forward_80_to_443'] = false
default['gitlab']['mattermost']['service_read_timeout'] = 300
default['gitlab']['mattermost']['service_write_timeout'] = 300


default['gitlab']['mattermost']['sql_driver_name'] = 'postgres'
default['gitlab']['mattermost']['sql_data_source'] = nil
default['gitlab']['mattermost']['sql_data_source_replicas'] = []
default['gitlab']['mattermost']['sql_max_idle_conns'] = 10
default['gitlab']['mattermost']['sql_max_open_conns'] = 10
default['gitlab']['mattermost']['sql_trace'] = false

# default['gitlab']['mattermost']['gitlab'] = {'Allow' => true, 'Secret' => "123", 'Id' => "123", "AuthEndpoint" => "aa", "TokenEndpoint" => "bb", "UserApiEndpoint" => "cc" }
default['gitlab']['mattermost']['gitlab'] = {}

default['gitlab']['mattermost']['file_max_file_size'] = 52428800
default['gitlab']['mattermost']['file_driver_name'] = "local"
default['gitlab']['mattermost']['file_directory'] = "/var/opt/gitlab/mattermost/data"
default['gitlab']['mattermost']['file_enable_public_link'] = true
default['gitlab']['mattermost']['file_thumbnail_width'] = 120
default['gitlab']['mattermost']['file_thumbnail_height'] = 100
default['gitlab']['mattermost']['file_preview_width'] = 1024
default['gitlab']['mattermost']['file_preview_height'] = 0
default['gitlab']['mattermost']['file_profile_width'] = 128
default['gitlab']['mattermost']['file_profile_height'] = 128
default['gitlab']['mattermost']['file_initial_font'] = 'luximbi.ttf'
default['gitlab']['mattermost']['file_amazon_s3_access_key_id'] = nil
default['gitlab']['mattermost']['file_amazon_s3_bucket'] = nil
default['gitlab']['mattermost']['file_amazon_s3_secret_access_key'] = nil
default['gitlab']['mattermost']['file_amazon_s3_bucket'] = nil
default['gitlab']['mattermost']["file_amazon_s3_endpoint"] = nil
default['gitlab']['mattermost']["file_amazon_s3_bucket_endpoint"] = nil
default['gitlab']['mattermost']["file_amazon_s3_location_constraint"] = false
default['gitlab']['mattermost']["file_amazon_s3_lowercase_bucket"] = false
default['gitlab']['mattermost']["file_amazon_s3_ssl"] = true

default['gitlab']['mattermost']['email_enable_sign_up_with_email'] = false
default['gitlab']['mattermost']['email_enable_sign_in_with_email'] = true
default['gitlab']['mattermost']['email_enable_sign_in_with_username'] = false
default['gitlab']['mattermost']['email_send_email_notifications'] = false
default['gitlab']['mattermost']['email_require_email_verification'] = false
default['gitlab']['mattermost']['email_feedback_name'] = nil
default['gitlab']['mattermost']['email_feedback_email'] = nil
default['gitlab']['mattermost']['email_feedback_organization'] = nil
default['gitlab']['mattermost']['email_smtp_username'] = nil
default['gitlab']['mattermost']['email_smtp_password'] = nil
default['gitlab']['mattermost']['email_smtp_server'] = nil
default['gitlab']['mattermost']['email_smtp_port'] = nil
default['gitlab']['mattermost']['email_connection_security'] = nil
default['gitlab']['mattermost']['email_send_push_notifications'] = false
default['gitlab']['mattermost']['email_push_notification_server'] = nil
default['gitlab']['mattermost']['email_push_notification_contents'] = "generic"
default['gitlab']['mattermost']['email_enable_batching'] = false
default['gitlab']['mattermost']['email_batching_buffer_size'] = 256
default['gitlab']['mattermost']['email_batching_interval'] = 30

default['gitlab']['mattermost']['ratelimit_enable_rate_limiter'] = false
default['gitlab']['mattermost']['ratelimit_per_sec'] = 10
default['gitlab']['mattermost']['ratelimit_memory_store_size'] = 10000
default['gitlab']['mattermost']['ratelimit_vary_by_remote_addr'] = true
default['gitlab']['mattermost']['ratelimit_vary_by_header'] = nil
default['gitlab']['mattermost']['ratelimit_max_burst'] = 100

default['gitlab']['mattermost']['privacy_show_email_address'] = true
default['gitlab']['mattermost']['privacy_show_full_name'] = true

default['gitlab']['mattermost']['localization_server_locale'] = "en"
default['gitlab']['mattermost']['localization_client_locale'] = "en"
default['gitlab']['mattermost']['localization_available_locales'] = ""

default['gitlab']['mattermost']['team_site_name'] = "GitLab Mattermost"
default['gitlab']['mattermost']['team_enable_team_creation'] = true
default['gitlab']['mattermost']['team_enable_user_creation'] = true
default['gitlab']['mattermost']['team_enable_open_server'] = false
default['gitlab']['mattermost']['team_max_users_per_team'] = 150
default['gitlab']['mattermost']['team_allow_public_link'] = true
default['gitlab']['mattermost']['team_allow_valet_default'] = false
default['gitlab']['mattermost']['team_restrict_creation_to_domains'] = nil
default['gitlab']['mattermost']['team_restrict_team_names'] = true
default['gitlab']['mattermost']['team_restrict_direct_message'] = "any"
default['gitlab']['mattermost']['team_max_channels_per_team'] = 2000

default['gitlab']['mattermost']['support_terms_of_service_link'] = "/static/help/terms.html"
default['gitlab']['mattermost']['support_privacy_policy_link'] = "/static/help/privacy.html"
default['gitlab']['mattermost']['support_about_link'] = "/static/help/about.html"
default['gitlab']['mattermost']['support_report_a_problem_link'] =  "/static/help/report_problem.html"
default['gitlab']['mattermost']['support_email'] =  "support@example.com"

default['gitlab']['mattermost']['gitlab_enable'] = false
default['gitlab']['mattermost']['gitlab_secret'] = nil
default['gitlab']['mattermost']['gitlab_id'] = nil
default['gitlab']['mattermost']['gitlab_scope'] = nil
default['gitlab']['mattermost']['gitlab_auth_endpoint'] = nil
default['gitlab']['mattermost']['gitlab_token_endpoint'] = nil
default['gitlab']['mattermost']['gitlab_user_api_endpoint'] = nil

default['gitlab']['mattermost']['webrtc_enable'] = false
default['gitlab']['mattermost']['webrtc_gateway_websocket_url'] = nil
default['gitlab']['mattermost']['webrtc_gateway_admin_url'] = nil
default['gitlab']['mattermost']['webrtc_gateway_admin_secret'] = nil
default['gitlab']['mattermost']['webrtc_gateway_stun_uri'] = nil
default['gitlab']['mattermost']['webrtc_gateway_turn_uri'] = nil
default['gitlab']['mattermost']['webrtc_gateway_turn_username'] = nil
default['gitlab']['mattermost']['webrtc_gateway_turn_shared_key'] = nil

####
# Mattermost NGINX
####
default['gitlab']['mattermost-nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['mattermost-nginx']['enable'] = false
default['gitlab']['mattermost-nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme",
  "X-Frame-Options" => "SAMEORIGIN",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade"
}

####
# GitLab Pages NGINX
####
default['gitlab']['pages-nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['pages-nginx']['enable'] = true

####
# GitLab Registry NGINX
####
default['gitlab']['registry-nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['registry-nginx']['enable'] = true
default['gitlab']['registry-nginx']['https'] = false
default['gitlab']['registry-nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
	"X-Forwarded-Proto" => "$scheme"
}
