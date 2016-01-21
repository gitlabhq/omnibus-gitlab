## Latest options listed at https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template

## Url on which GitLab will be reachable.
## For more details on configuring external_url see:
## https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#configuring-the-external-url-for-gitlab
external_url 'GENERATED_EXTERNAL_URL'


## Note: configuration settings below are optional.
## Uncomment and change the value.
############################
# gitlab.yml configuration #
############################

# gitlab_rails['gitlab_ssh_host'] = 'ssh.host_example.com'
# gitlab_rails['time_zone'] = 'UTC'
# gitlab_rails['gitlab_email_enabled'] = true
# gitlab_rails['gitlab_email_from'] = 'example@example.com'
# gitlab_rails['gitlab_email_display_name'] = 'Example'
# gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
# gitlab_rails['gitlab_default_can_create_group'] = true
# gitlab_rails['gitlab_username_changing_enabled'] = true
# gitlab_rails['gitlab_default_theme'] = 2
# gitlab_rails['gitlab_default_projects_features_issues'] = true
# See http://doc.gitlab.com/ce/customization/issue_closing.html for more information about this pattern.
# gitlab_rails['gitlab_issue_closing_pattern'] = "((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)"
# gitlab_rails['gitlab_default_projects_features_merge_requests'] = true
# gitlab_rails['gitlab_default_projects_features_wiki'] = true
# gitlab_rails['gitlab_default_projects_features_snippets'] = false
# gitlab_rails['gitlab_default_projects_features_builds'] = true
# gitlab_rails['gitlab_repository_downloads_path'] = 'tmp/repositories'
# gitlab_rails['gravatar_plain_url'] = 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
# gitlab_rails['gravatar_ssl_url'] = 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
# gitlab_rails['stuck_ci_builds_worker_cron'] = "0 0 * * *"
# gitlab_rails['historical_data_worker_cron'] = "0 12 * * *"
# gitlab_rails['update_all_mirrors_worker_cron'] = "0 * * * *"
# gitlab_rails['ldap_sync_worker_cron'] = "30 1 * * *"
# gitlab_rails['webhook_timeout'] = 10

## Reply by email
# Allow users to comment on issues and merge requests by replying to notification emails.
# For documentation on how to set this up, see http://doc.gitlab.com/ce/incoming_email/README.html
# gitlab_rails['incoming_email_enabled'] = true
#
# # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
# # The `+%{key}` placeholder is added after the user part, after a `+` character, before the `@`.
# gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"
#
# # Email account username
# # With third party providers, this is usually the full email address.
# # With self-hosted email servers, this is usually the user part of the email address.
# gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"
# # Email account password
# gitlab_rails['incoming_email_password'] = "[REDACTED]"
#
# # IMAP server host
# gitlab_rails['incoming_email_host'] = "imap.gmail.com"
# # IMAP server port
# gitlab_rails['incoming_email_port'] = 993
# # Whether the IMAP server uses SSL
# gitlab_rails['incoming_email_ssl'] = true
# # Whether the IMAP server uses StartTLS
# gitlab_rails['incoming_email_start_tls'] = false
#
# # The mailbox where incoming mail will end up. Usually "inbox".
# gitlab_rails['incoming_email_mailbox_name'] = "inbox"
#
# gitlab_rails['incoming_email_log_directory'] = "/var/log/gitlab/mailroom"

## Build Artifacts
# gitlab_rails['artifacts_enabled'] = true
# gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"

## Git LFS
# gitlab_rails['lfs_enabled'] = true
# gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"

## ElasticSearch (EE only)
# gitlab_rails['elasticsearch_enabled'] = false
# gitlab_rails['elasticsearch_host'] = "localhost"
# gitlab_rails['elasticsearch_port'] = 9200

## GitLab Pages (EE only)
# gitlab_rails['pages_path'] = "/mnt/storage/pages"

## For setting up LDAP
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#setting-up-ldap-sign-in
## Be careful not to break the identation in the ldap_servers block. It is in
## yaml format and the spaces must be retained. Using tabs will not work.

# gitlab_rails['ldap_enabled'] = false
# gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
#   main: # 'main' is the GitLab 'provider ID' of this LDAP server
#     label: 'LDAP'
#     host: '_your_ldap_server'
#     port: 389
#     uid: 'sAMAccountName'
#     method: 'plain' # "tls" or "ssl" or "plain"
#     bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
#     password: '_the_password_of_the_bind_user'
#     active_directory: true
#     allow_username_or_email_login: false
#     block_auto_created_users: false
#     base: ''
#     user_filter: ''
#     attributes:
#       username: ['uid', 'userid', 'sAMAccountName']
#       email:    ['mail', 'email', 'userPrincipalName']
#       name:       'cn'
#       first_name: 'givenName'
#       last_name:  'sn'
#     ## EE only
#     group_base: ''
#     admin_group: ''
#     sync_ssh_keys: false
#
#   secondary: # 'secondary' is the GitLab 'provider ID' of second LDAP server
#     label: 'LDAP'
#     host: '_your_ldap_server'
#     port: 389
#     uid: 'sAMAccountName'
#     method: 'plain' # "tls" or "ssl" or "plain"
#     bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
#     password: '_the_password_of_the_bind_user'
#     active_directory: true
#     allow_username_or_email_login: false
#     block_auto_created_users: false
#     base: ''
#     user_filter: ''
#     attributes:
#       username: ['uid', 'userid', 'sAMAccountName']
#       email:    ['mail', 'email', 'userPrincipalName']
#       name:       'cn'
#       first_name: 'givenName'
#       last_name:  'sn'
#     ## EE only
#     group_base: ''
#     admin_group: ''
#     sync_ssh_keys: false
# EOS

## Setting up Kerberos (EE only)
## See http://doc.gitlab.com/ee/integration/kerberos.html#http-git-access
# gitlab_rails['kerberos_enabled'] = true
# gitlab_rails['kerberos_keytab'] = /etc/http.keytab
# gitlab_rails['kerberos_service_principal_name'] = HTTP/gitlab.example.com@EXAMPLE.COM
# gitlab_rails['kerberos_use_dedicated_port'] = true
# gitlab_rails['kerberos_port'] = 8443
# gitlab_rails['kerberos_https'] = true

## For setting up omniauth
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#omniauth-google-twitter-github-login

# gitlab_rails['omniauth_enabled'] = true
# gitlab_rails['omniauth_allow_single_sign_on'] = false
# gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
# gitlab_rails['omniauth_block_auto_created_users'] = true
# gitlab_rails['omniauth_auto_link_ldap_user'] = false
# gitlab_rails['omniauth_providers'] = [
#   {
#     "name" => "google_oauth2",
#     "app_id" => "YOUR APP ID",
#     "app_secret" => "YOUR APP SECRET",
#     "args" => { "access_type" => "offline", "approval_prompt" => "" }
#   }
# ]
#
# If you setup bitbucket importer under omniauth providers you will need to add the keys
# which will allow connection between bitbucket and gitlab.
# For details see http://doc.gitlab.com/ce/integration/bitbucket.html
# gitlab_rails['bitbucket'] = {
#  'known_hosts_key' => 'bitbucket.org,207.223.240.182 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==',
#  'private_key' => '-----BEGIN RSA PRIVATE KEY-----
#   MIIEowIBAAKCAQEAyXxYHwz2KjcwSjTREwlhYHqrf/8U0UM8ej3cqQ551gE4Wo3t
#   -----END RSA PRIVATE KEY-----',
#  'public_key' => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJfFgfDPYqN git@gitlab.example.com'
# }

## For setting up backups
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#backups

# gitlab_rails['manage_backup_path'] = true
# gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
# gitlab_rails['backup_archive_permissions'] = 0644 # See: http://doc.gitlab.com/ce/raketasks/backup_restore.html#backup-archive-permissions
# gitlab_rails['backup_pg_schema'] = 'public'
# gitlab_rails['backup_keep_time'] = 604800
# gitlab_rails['backup_upload_connection'] = {
#   'provider' => 'AWS',
#   'region' => 'eu-west-1',
#   'aws_access_key_id' => 'AKIAKIAKI',
#   'aws_secret_access_key' => 'secret123'
# }
# gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
# gitlab_rails['backup_multipart_chunk_size'] = 104857600
# gitlab_rails['backup_encryption'] = 'AES256' # Turns on AWS Server-Side Encryption with Amazon S3-Managed Keys for backups

## For setting up different data storing directory
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#storing-git-data-in-an-alternative-directory
## If you want to use a single non-default directory to store git data use
## a path that doesn't contain symlinks.
# git_data_dir "/var/opt/gitlab/git-data"


## For storing GitLab application uploads
# gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'

# DEPRECATED: gitlab_rails['satellites_timeout'] = 30

## GitLab Shell settings for GitLab
# gitlab_rails['gitlab_shell_ssh_port'] = 22
# gitlab_rails['git_max_size'] = 20971520
# gitlab_rails['git_timeout'] = 10

## Extra customization
# gitlab_rails['extra_google_analytics_id'] = '_your_tracking_id'
# gitlab_rails['extra_piwik_url'] = '_your_piwik_url'
# gitlab_rails['extra_piwik_site_id'] = '_your_piwik_site_id'

# gitlab_rails['env'] = {
#   'BUNDLE_GEMFILE' => "/opt/gitlab/embedded/service/gitlab-rails/Gemfile",
#   'PATH' => "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin"
# }

# gitlab_rails['rack_attack_git_basic_auth'] = {
#   'enabled' => true,
#   'ip_whitelist' => ["127.0.0.1"],
#   'maxretry' => 10,
#   'findtime' => 60,
#   'bantime' => 3600
# }

# We do not recommend changing these directories.
# gitlab_rails['dir'] = "/var/opt/gitlab/gitlab-rails"
# gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"

###############################
# GitLab application settings #
###############################

# gitlab_rails['uploads_directory'] = "/var/opt/gitlab/gitlab-rails/uploads"
# gitlab_rails['rate_limit_requests_per_period'] = 10
# gitlab_rails['rate_limit_period'] = 60

# Change the initial default admin password.
# Only applicable on inital setup, changing this setting after database is created and seeded
# won't yield any change.
# gitlab_rails['initial_root_password'] = "password"

############################
# GitLab database settings #
############################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/database.md#database-settings
## Only needed if you use an external database.

# gitlab_rails['db_adapter'] = "postgresql"
# gitlab_rails['db_encoding'] = "unicode"
# gitlab_rails['db_collation'] = nil
# gitlab_rails['db_database'] = "gitlabhq_production"
# gitlab_rails['db_pool'] = 10
# gitlab_rails['db_username'] = "gitlab"
# gitlab_rails['db_password'] = nil
# gitlab_rails['db_host'] = nil
# gitlab_rails['db_port'] = 5432
# gitlab_rails['db_socket'] = nil
# gitlab_rails['db_sslmode'] = nil
# gitlab_rails['db_sslrootcert'] = nil


#########################
# GitLab redis settings #
#########################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/redis.md#redis-settings
## Connect to your own redis instance.

# gitlab_rails['redis_host'] = "127.0.0.1"
# gitlab_rails['redis_port'] = nil
# gitlab_rails['redis_password'] = nil
# gitlab_rails['redis_database'] = 0
# gitlab_rails['redis_socket'] = "/var/opt/gitlab/redis/redis.socket"

################################
# GitLab email server settings #
################################
# see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/smtp.md#smtp-settings
# Use smtp instead of sendmail/postfix.

# gitlab_rails['smtp_enable'] = true
# gitlab_rails['smtp_address'] = "smtp.server"
# gitlab_rails['smtp_port'] = 456
# gitlab_rails['smtp_user_name'] = "smtp user"
# gitlab_rails['smtp_password'] = "smtp password"
# gitlab_rails['smtp_domain'] = "example.com"
# gitlab_rails['smtp_authentication'] = "login"
# gitlab_rails['smtp_enable_starttls_auto'] = true
# gitlab_rails['smtp_tls'] = false
# gitlab_rails['smtp_openssl_verify_mode'] = 'none' # Can be: 'none', 'peer', 'client_once', 'fail_if_no_peer_cert', see http://api.rubyonrails.org/classes/ActionMailer/Base.html
# gitlab_rails['smtp_ca_path'] = "/etc/ssl/certs"
# gitlab_rails['smtp_ca_file'] = "/etc/ssl/certs/ca-certificates.crt"

####################
# GitLab Workhorse #
####################
# see https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/README.md

# gitlab_workhorse['enable'] = true
# gitlab_workhorse['ha'] = false
# gitlab_workhorse['listen_network'] = "unix"
# gitlab_workhorse['listen_umask'] = 000
# gitlab_workhorse['listen_addr'] = "/var/opt/gitlab/gitlab-workhorse/socket"
# gitlab_workhorse['auth_backend'] = "http://localhost:8080"
# gitlab_workhorse['auth_socket'] = "''" # the empty string is the default in gitlab-workhorse option parser
# gitlab_workhorse['pprof_listen_addr'] = "''" # put an empty string on the command line
# gitlab_workhorse['dir'] = "/var/opt/gitlab/gitlab-workhorse"
# gitlab_workhorse['log_dir'] = "/var/log/gitlab/gitlab-workhorse"
# gitlab_workhorse['proxy_headers_timeout'] = "1m0s"
# gitlab_workhorse['env'] = {
#   'PATH' => "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin"
# }

###############
# GitLab user #
###############
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#changing-the-name-of-the-git-user-group
## Modify default git user.


# user['username'] = "git"
# user['group'] = "git"
# user['uid'] = nil
# user['gid'] = nil
# # The shell for the git user
# user['shell'] = "/bin/sh"
# # The home directory for the git user
# user['home'] = "/var/opt/gitlab"
# user['git_user_name'] = "GitLab"
# user['git_user_email'] = "gitlab@#{node['fqdn']}"

##################
# GitLab Unicorn #
##################
## Tweak unicorn settings.

# unicorn['worker_timeout'] = 60
# unicorn['worker_processes'] = 2

## Advanced settings
# unicorn['listen'] = '127.0.0.1'
# unicorn['port'] = 8080
# unicorn['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
# unicorn['pidfile'] = '/opt/gitlab/var/unicorn/unicorn.pid'
# unicorn['tcp_nopush'] = true
# unicorn['backlog_socket'] = 1024
# Make sure somaxconn is equal or higher then backlog_socket
# unicorn['somaxconn'] = 1024
# We do not recommend changing this setting
# unicorn['log_directory'] = "/var/log/gitlab/unicorn"

## Only change these settings if you understand well what they mean
## see https://about.gitlab.com/2015/06/05/how-gitlab-uses-unicorn-and-unicorn-worker-killer/
## and https://github.com/kzk/unicorn-worker-killer
# unicorn['worker_memory_limit_min'] = "300*(1024**2)"
# unicorn['worker_memory_limit_max'] = "350*(1024**2)"


##################
# GitLab Sidekiq #
##################

# sidekiq['log_directory'] = "/var/log/gitlab/sidekiq"
# sidekiq['shutdown_timeout'] = 4
# sidekiq['concurrency'] = 25


################
# gitlab-shell #
################

# gitlab_shell['audit_usernames'] = false
# gitlab_shell['log_level'] = 'INFO'
# gitlab_shell['http_settings'] = { user: 'username', password: 'password', ca_file: '/etc/ssl/cert.pem', ca_path: '/etc/pki/tls/certs', self_signed_cert: false}
# gitlab_shell['log_directory'] = "/var/log/gitlab/gitlab-shell/"

## If enabled, git-annex needs to be installed on the server where gitlab is setup
# For Debian and Ubuntu systems this can be done with: sudo apt-get install git-annex
# For CentOS: sudo yum install epel-release && sudo yum install git-annex
# gitlab_shell['git_annex_enabled'] = false

#####################
# GitLab PostgreSQL #
#####################

# postgresql['enable'] = true
# postgresql['listen_address'] = nil
# postgresql['port'] = 5432
# postgresql['data_dir'] = "/var/opt/gitlab/postgresql/data"
# postgresql['shared_buffers'] = "256MB" # recommend value is 1/4 of total RAM, up to 14GB.

## Advanced settings
# postgresql['ha'] = false
# postgresql['dir'] = "/var/opt/gitlab/postgresql"
# postgresql['log_directory'] = "/var/log/gitlab/postgresql"
# postgresql['username'] = "gitlab-psql"
# postgresql['uid'] = nil
# postgresql['gid'] = nil
# postgresql['shell'] = "/bin/sh"
# postgresql['home'] = "/var/opt/gitlab/postgresql"
# postgresql['user_path'] = "/opt/gitlab/embedded/bin:/opt/gitlab/bin:$PATH"
# postgresql['sql_user'] = "gitlab"
# postgresql['sql_ci_user'] = "gitlab_ci"
# postgresql['max_connections'] = 200
# postgresql['md5_auth_cidr_addresses'] = []
# postgresql['trust_auth_cidr_addresses'] = []
# postgresql['shmmax'] =  17179869184 # or 4294967295
# postgresql['shmall'] =  4194304 # or 1048575
# postgresql['work_mem'] = "8MB"
# postgresql['effective_cache_size'] = "1MB"
# postgresql['checkpoint_segments'] = 10
# postgresql['checkpoint_timeout'] = "5min"
# postgresql['checkpoint_completion_target'] = 0.9
# postgresql['checkpoint_warning'] = "30s"


################
# GitLab Redis #
################
## Can be disabled if you are using your own redis instance.

# redis['enable'] = true
# redis['username'] = "gitlab-redis"
# redis['uid'] = nil
# redis['gid'] = nil


#####################
# GitLab Web server #
#####################
## see: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/nginx.md#using-a-non-bundled-web-server
## When bundled nginx is disabled we need to add the external webserver user to the GitLab webserver group.

# web_server['external_users'] = []
# web_server['username'] = 'gitlab-www'
# web_server['group'] = 'gitlab-www'
# web_server['uid'] = nil
# web_server['gid'] = nil
# web_server['shell'] = '/bin/false'
# web_server['home'] = '/var/opt/gitlab/nginx'


################
# GitLab Nginx #
################
## see: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/nginx.md

# nginx['enable'] = true
# nginx['client_max_body_size'] = '250m'
# nginx['redirect_http_to_https'] = false
# nginx['redirect_http_to_https_port'] = 80
# nginx['ssl_client_certificate'] = "/etc/gitlab/ssl/ca.crt" # Most root CA's are included by default
# nginx['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
# nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
# nginx['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
# nginx['ssl_prefer_server_ciphers'] = "on"
# nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
# nginx['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# nginx['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# nginx['ssl_dhparam'] = nil # Path to dhparams.pem, eg. /etc/gitlab/ssl/dhparams.pem
# nginx['listen_addresses'] = ['*']
# nginx['listen_port'] = nil # override only if you use a reverse proxy: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#setting-the-nginx-listen-port
# nginx['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#supporting-proxied-ssl
# nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
# nginx['custom_nginx_config'] = "include /etc/nginx/conf.d/example.conf;"
# nginx['proxy_read_timeout'] = 300
# nginx['proxy_connect_timeout'] = 300

## Advanced settings
# nginx['dir'] = "/var/opt/gitlab/nginx"
# nginx['log_directory'] = "/var/log/gitlab/nginx"
# nginx['worker_processes'] = 4
# nginx['worker_connections'] = 10240
# nginx['log_format'] = '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
# nginx['sendfile'] = 'on'
# nginx['tcp_nopush'] = 'on'
# nginx['tcp_nodelay'] = 'on'
# nginx['gzip'] = "on"
# nginx['gzip_http_version'] = "1.0"
# nginx['gzip_comp_level'] = "2"
# nginx['gzip_proxied'] = "any"
# nginx['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
# nginx['keepalive_timeout'] = 65
# nginx['cache_max_size'] = '5000m'



##################
# GitLab Logging #
##################
## see: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#logs

# logging['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
# logging['svlogd_num'] = 30 # keep 30 rotated log files
# logging['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
# logging['svlogd_filter'] = "gzip" # compress logs with gzip
# logging['svlogd_udp'] = nil # transmit log messages via UDP
# logging['svlogd_prefix'] = nil # custom prefix for log messages
# logging['logrotate_frequency'] = "daily" # rotate logs daily
# logging['logrotate_size'] = nil # do not rotate by size by default
# logging['logrotate_rotate'] = 30 # keep 30 rotated logs
# logging['logrotate_compress'] = "compress" # see 'man logrotate'
# logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
# logging['logrotate_postrotate'] = nil # no postrotate command by default
# Enterprise Edition only
# logging['udp_log_shipping_host'] = nil # remote host to ship log messages to via UDP
# logging['udp_log_shipping_port'] = 514 # remote host to ship log messages to via UDP

#############
# Logrotate #
#############
## see: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#logrotate
## You can disable built in logrotate feature.

# logrotate['enable'] = true

#############################
# Users and groups accounts #
#############################
## Should omnibus-gitlab package manage users and groups accounts.
## Only set if creating accounts manually
##

# manage_accounts['enable'] = true

#######
# Git #
#######
## Advanced setting for configuring git system settings for omnibus-gitlab internal git
## For multiple options under one header use array of comma separated values, eg.
## { "receive" => ["fsckObjects = true"], "alias" => ["st = status", "co = checkout"] }

# omnibus_gitconfig['system'] = { "receive" => ["fsckObjects = true"] }

############################################
# Url on which GitLab CI will be reachable #
############################################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/gitlab-ci/README.md

# ci_external_url 'http://ci.example.com'


#################################
# application.yml configuration #
#################################

# gitlab_ci['gitlab_server'] = { "url" => 'http://gitlab.example.com', "app_id" => '12345678', "app_secret" => 'QWERTY12345' }

# gitlab_ci['gitlab_ci_email_from'] = 'gitlab-ci@example.com'
# gitlab_ci['gitlab_ci_support_email'] = 'gitlab-ci@example.com'
# gitlab_ci['gitlab_ci_all_broken_builds'] = true
# gitlab_ci['gitlab_ci_add_pusher'] = true
# gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'

# gitlab_ci['gravatar_enabled'] = true
# gitlab_ci['gravatar_plain_url'] = "http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm"
# gitlab_ci['gravatar_ssl_url'] =  "https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm"

## For setting up backups
## see https://gitlab.com/gitlab-org/omnibus-gitlab/blob/629def0a7a26e7c2326566f0758d4a27857b52a3/README.md#backups

# gitlab_ci['backup_path'] = "/var/opt/gitlab/ci-backups"
# gitlab_ci['backup_keep_time'] = 604800
# gitlab_ci['backup_upload_connection'] = {
#   'provider' => 'AWS',
#   'region' => 'eu-west-1',
#   'aws_access_key_id' => 'AKIAKIAKI',
#   'aws_secret_access_key' => 'secret123'
# }
# gitlab_ci['backup_upload_remote_directory'] = 'my.s3.bucket'
# gitlab_ci['backup_multipart_chunk_size'] = 104857600

###############################
# GitLab CI database settings #
###############################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/database.md#database-settings
## Only needed if you use an external database.

# gitlab_ci['db_adapter'] = "postgresql"
# gitlab_ci['db_encoding'] = "unicode"
# gitlab_ci['db_database'] = "gitlab_ci_production"
# gitlab_ci['db_pool'] = 10
# gitlab_ci['db_username'] = "gitlab_ci"
# gitlab_ci['db_password'] = nil
# gitlab_ci['db_host'] = nil
# gitlab_ci['db_port'] = 5432
# gitlab_ci['db_socket'] = nil
# gitlab_ci['db_sslmode'] = nil
# gitlab_ci['db_sslrootcert'] = nil

############################
# GitLab CI redis settings #
############################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/redis.md#redis-settings
## Connect to your own redis instance.

# gitlab_ci['redis_host'] = "127.0.0.1"
# gitlab_ci['redis_port'] = nil
# gitlab_ci['redis_socket'] = "/var/opt/gitlab/ci-redis/redis.socket"

###################################
# GitLab CI email server settings #
###################################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/smtp.md#smtp-settings

# gitlab_ci['smtp_enable'] = true
# gitlab_ci['smtp_address'] = "smtp.server"
# gitlab_ci['smtp_port'] = 456
# gitlab_ci['smtp_user_name'] = "smtp user"
# gitlab_ci['smtp_password'] = "smtp password"
# gitlab_ci['smtp_domain'] = "example.com"
# gitlab_ci['smtp_authentication'] = "login"
# gitlab_ci['smtp_enable_starttls_auto'] = true
# gitlab_ci['smtp_tls'] = false
# gitlab_ci['smtp_openssl_verify_mode'] = false


#############
# GitLab CI #
#############

# gitlab_ci['schedule_builds_minute'] = "0"
# gitlab_ci['env'] = {
#   'BUNDLE_GEMFILE' => "/opt/gitlab/embedded/service/gitlab-ci/Gemfile",
#   'PATH' => "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin"
# }

# gitlab_ci['username'] = "gitlab-ci"
# gitlab_ci['uid'] = nil
# gitlab_ci['gid'] = nil


#####################
# GitLab CI Unicorn #
#####################
## Tweak unicorn settings.

# ci_unicorn['worker_processes'] = 2
# ci_unicorn['worker_timeout'] = 60
## Advanced settings
# ci_unicorn['listen'] = '127.0.0.1'
# ci_unicorn['port'] = 8181
# ci_unicorn['socket'] = '/var/opt/gitlab/gitlab-ci/sockets/gitlab.socket'
# ci_unicorn['pidfile'] = '/opt/gitlab/var/ci-unicorn/unicorn.pid'
# ci_unicorn['tcp_nopush'] = true
# ci_unicorn['backlog_socket'] = 1024


###################
# GitLab CI Redis #
###################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/redis.md
## You can turn off bundled redis if you want to use your own redis instanance

# ci_redis['enable'] = true


###################
# GitLab CI NGINX #
###################
## see https://gitlab.com/gitlab-org/omnibus-gitlab/tree/629def0a7a26e7c2326566f0758d4a27857b52a3/doc/settings/nginx.md
## You can tell the bundled NGINX that it should not serve up GitLab CI by setting ci_nginx['enable'] to false.

# ci_nginx['enable'] = false
# ci_nginx['client_max_body_size'] = '250m'
# ci_nginx['redirect_http_to_https'] = false
# ci_nginx['redirect_http_to_https_port'] = 80
# ci_nginx['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
# ci_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
# ci_nginx['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
# ci_nginx['ssl_prefer_server_ciphers'] = "on"
# ci_nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
# ci_nginx['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# ci_nginx['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# ci_nginx['ssl_dhparam'] = nil # Path to ci_dhparams.pem, eg. /etc/gitlab/ssl/ci_dhparams.pem
# ci_nginx['listen_addresses'] = ['*']
# ci_nginx['listen_port'] = nil # override only if you use a reverse proxy: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#setting-the-nginx-listen-port
# ci_nginx['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#supporting-proxied-ssl
# ci_nginx['custom_gitlab_ci_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
# ci_nginx['custom_nginx_config'] = "include /etc/nginx/conf.d/example.conf;"
# ci_nginx['resolver'] = "8.8.8.8 8.8.4.4"

## Advanced settings
# ci_nginx['dir'] = "/var/opt/gitlab/nginx"
# ci_nginx['log_directory'] = "/var/log/gitlab/nginx"
# ci_nginx['worker_processes'] = 4
# ci_nginx['worker_connections'] = 10240
# ci_nginx['sendfile'] = 'on'
# ci_nginx['tcp_nopush'] = 'on'
# ci_nginx['tcp_nodelay'] = 'on'
# ci_nginx['gzip'] = "on"
# ci_nginx['gzip_http_version'] = "1.0"
# ci_nginx['gzip_comp_level'] = "2"
# ci_nginx['gzip_proxied'] = "any"
# ci_nginx['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
# ci_nginx['keepalive_timeout'] = 65
# ci_nginx['cache_max_size'] = '5000m'


#####################
# GitLab Mattermost #
#####################

# mattermost_external_url 'http://mattermost.example.com'
#
# mattermost['enable'] = false
# mattermost['username'] = 'mattermost'
# mattermost['group'] = 'mattermost'
# mattermost['home'] = '/var/opt/gitlab/mattermost'
# mattermost['database_name'] = 'mattermost_production'

# mattermost['service_use_ssl'] = false
# mattermost['service_address'] = "127.0.0.1"
# mattermost['service_port'] = "8065"

# mattermost['service_maximum_login_attempts'] = 10
# mattermost['service_segment_developer_key'] = nil
# mattermost['service_google_developer_key'] = nil
# mattermost['service_enable_incoming_webhooks'] = true
# mattermost['service_enable_post_username_override'] = false
# mattermost['service_enable_post_icon_override'] = false
# mattermost['service_enable_testing'] = false
# mattermost['service_enable_security_fix_alert'] = true
# mattermost['service_enable_outgoing_webhooks'] = true
# mattermost['service_enable_oauth_service_provider'] = false
# mattermost['service_enable_developer'] = false
# mattermost['service_session_length_web_in_days'] = 30
# mattermost['service_session_length_mobile_in_days'] = 30
# mattermost['service_session_length_sso_in_days'] = 30
# mattermost['service_session_cache_in_minutes'] = 10

# mattermost['team_site_name'] = "GitLab Mattermost"
# mattermost['team_max_users_per_team'] = 150
# mattermost['team_enable_team_creation'] = true
# mattermost['team_enable_user_creation'] = true
# mattermost['team_allow_public_link'] = true
# mattermost['team_allow_valet_default'] = false
# mattermost['team_default_color'] = '#2389D7'
# mattermost['team_restrict_creation_to_domains'] = "gmail.com"
# mattermost['team_restrict_team_names'] = true
# mattermost['team_enable_team_listing'] = false


# mattermost['sql_driver_name'] = 'mysql'
# mattermost['sql_data_source'] = "mmuser:mostest@tcp(dockerhost:3306)/mattermost_test?charset=utf8mb4,utf8"
# mattermost['sql_data_source_replicas'] = ["mmuser:mostest@tcp(dockerhost:3306)/mattermost_test?charset=utf8mb4,utf8"]
# mattermost['sql_max_idle_conns'] = 10
# mattermost['sql_max_open_conns'] = 10
# mattermost['sql_trace'] = false

# mattermost['log_file_directory'] = '/var/log/gitlab/mattermost'
# mattermost['log_console_enable'] = true
# mattermost['log_console_level'] = 'INFO'
# mattermost['log_enable_file'] = false
# mattermost['log_file_level'] = 'INFO'
# mattermost['log_file_format'] = nil

# mattermost['gitlab_enable'] = false
# mattermost['gitlab_secret'] = "123456789"
# mattermost['gitlab_id'] = "12345656"
# mattermost['gitlab_scope'] = ""
# mattermost['gitlab_auth_endpoint'] = "http://gitlab.example.com/oauth/authorize"
# mattermost['gitlab_token_endpoint'] = "http://gitlab.example.com/oauth/token"
# mattermost['gitlab_user_api_endpoint'] = "http://gitlab.example.com/api/v3/user"

# mattermost['aws'] = {'S3AccessKeyId' => '123', 'S3SecretAccessKey' => '123', 'S3Bucket' => 'aa', 'S3Region' => 'bb'}

# mattermost['email_enable_sign_up_with_email'] = true
# mattermost['email_send_email_notifications'] = false
# mattermost['email_require_email_verification'] = false
# mattermost['email_smtp_username'] = nil
# mattermost['email_smtp_password'] = nil
# mattermost['email_smtp_server'] = nil
# mattermost['email_smtp_port'] = nil
# mattermost['email_connection_security'] = nil
# mattermost['email_feedback_name'] = nil
# mattermost['email_feedback_email'] = nil
# mattermost['email_send_push_notifications'] = true
# mattermost['email_push_notification_server'] = ""

# mattermost['file_driver_name'] = "local"
# mattermost['file_directory'] = "/var/opt/gitlab/mattermost/data"
# mattermost['file_enable_public_link'] = true
# mattermost['file_thumbnail_width'] = 120
# mattermost['file_thumbnail_height'] = 100
# mattermost['file_preview_width'] = 1024
# mattermost['file_preview_height'] = 0
# mattermost['file_profile_width'] = 128
# mattermost['file_profile_height'] = 128
# mattermost['file_initial_font'] = 'luximbi.ttf'
# mattermost['file_amazon_s3_access_key_id'] = nil
# mattermost['file_amazon_s3_bucket'] = nil
# mattermost['file_amazon_s3_secret_access_key'] = nil
# mattermost['file_amazon_s3_bucket'] = nil
# mattermost["file_amazon_s3_endpoint"] = nil
# mattermost["file_amazon_s3_bucket_endpoint"] = nil
# mattermost["file_amazon_s3_location_constraint"] = false
# mattermost["file_amazon_s3_lowercase_bucket"] = false

# mattermost['ratelimit_enable_rate_limiter'] = true
# mattermost['ratelimit_per_sec'] = 10
# mattermost['ratelimit_memory_store_size'] = 10000
# mattermost['ratelimit_vary_by_remote_addr'] = true
# mattermost['ratelimit_vary_by_header'] = nil

# mattermost['support_terms_of_service_link'] = "/static/help/terms.html"
# mattermost['support_privacy_policy_link'] = "/static/help/privacy.html"
# mattermost['support_about_link'] = "/static/help/about.html"
# mattermost['support_report_a_problem_link'] =  "/static/help/report_problem.html"
# mattermost['support_email'] =  "support@example.com"

# mattermost['privacy_show_email_address'] = true
# mattermost['privacy_show_full_name'] = true


####################
# Mattermost NGINX #
####################

# mattermost_nginx['enable'] = false
# mattermost_nginx['client_max_body_size'] = '250m'
# mattermost_nginx['redirect_http_to_https'] = false
# mattermost_nginx['redirect_http_to_https_port'] = 80
# mattermost_nginx['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
# mattermost_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
# mattermost_nginx['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
# mattermost_nginx['ssl_prefer_server_ciphers'] = "on"
# mattermost_nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
# mattermost_nginx['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# mattermost_nginx['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# mattermost_nginx['ssl_dhparam'] = nil # Path to ci_dhparams.pem, eg. /etc/gitlab/ssl/ci_dhparams.pem
# mattermost_nginx['listen_addresses'] = ['*']
# mattermost_nginx['listen_port'] = nil # override only if you use a reverse proxy: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#setting-the-nginx-listen-port
# mattermost_nginx['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#supporting-proxied-ssl
# mattermost_nginx['custom_gitlab_mattermost_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
# mattermost_nginx['custom_nginx_config'] = "include /etc/nginx/conf.d/example.conf;"

## Advanced settings
# mattermost_nginx['dir'] = "/var/opt/gitlab/nginx"
# mattermost_nginx['log_directory'] = "/var/log/gitlab/nginx"
# mattermost_nginx['worker_processes'] = 4
# mattermost_nginx['worker_connections'] = 10240
# mattermost_nginx['sendfile'] = 'on'
# mattermost_nginx['tcp_nopush'] = 'on'
# mattermost_nginx['tcp_nodelay'] = 'on'
# mattermost_nginx['gzip'] = "on"
# mattermost_nginx['gzip_http_version'] = "1.0"
# mattermost_nginx['gzip_comp_level'] = "2"
# mattermost_nginx['gzip_proxied'] = "any"
# mattermost_nginx['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
# mattermost_nginx['keepalive_timeout'] = 65
# mattermost_nginx['cache_max_size'] = '5000m'

####################
# GitLab Pages
####################

## Define to enable GitLab Pages
# pages_external_url "http://pages.example.com/"

####################
# GitLab Pages NGINX #
####################

# pages_nginx['enable'] = false
# pages_nginx['redirect_http_to_https'] = false
# pages_nginx['redirect_http_to_https_port'] = 80
# pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
# pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
# pages_nginx['ssl_ciphers'] = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
# pages_nginx['ssl_prefer_server_ciphers'] = "on"
# pages_nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
# pages_nginx['ssl_session_cache'] = "builtin:1000  shared:SSL:10m" # recommended in http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# pages_nginx['ssl_session_timeout'] = "5m" # default according to http://nginx.org/en/docs/http/ngx_http_ssl_module.html
# pages_nginx['ssl_dhparam'] = nil # Path to ci_dhparams.pem, eg. /etc/gitlab/ssl/ci_dhparams.pem
# pages_nginx['listen_addresses'] = ['*']
# pages_nginx['listen_port'] = nil # override only if you use a reverse proxy: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#setting-the-nginx-listen-port
# pages_nginx['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#supporting-proxied-ssl
# pages_nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"

## Advanced settings
# pages_nginx['dir'] = "/var/opt/gitlab/nginx"
# pages_nginx['log_directory'] = "/var/log/gitlab/nginx"
