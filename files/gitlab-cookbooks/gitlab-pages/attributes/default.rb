####
# GitLab Pages Daemon
####
default['gitlab-pages']['enable'] = false
default['gitlab-pages']['external_http'] = []
default['gitlab-pages']['external_https'] = []
default['gitlab-pages']['external_https_proxyv2'] = []
default['gitlab-pages']['listen_proxy'] = "localhost:8090"
default['gitlab-pages']['gitlab_server'] = nil
default['gitlab-pages']['internal_gitlab_server'] = nil
default['gitlab-pages']['metrics_address'] = nil
default['gitlab-pages']['pages_path'] = nil
default['gitlab-pages']['enable_disk'] = nil
default['gitlab-pages']['domain'] = nil
default['gitlab-pages']['cert'] = nil
default['gitlab-pages']['cert_key'] = nil
default['gitlab-pages']['redirect_http'] = false
default['gitlab-pages']['use_http2'] = true
default['gitlab-pages']['dir'] = "/var/opt/gitlab/gitlab-pages"
default['gitlab-pages']['log_directory'] = "/var/log/gitlab/gitlab-pages"
default['gitlab-pages']['status_uri'] = nil
default['gitlab-pages']['max_connections'] = nil
default['gitlab-pages']['max_uri_length'] = nil
default['gitlab-pages']['log_format'] = "json"
default['gitlab-pages']['artifacts_server'] = true
default['gitlab-pages']['artifacts_server_url'] = nil
default['gitlab-pages']['artifacts_server_timeout'] = 10
default['gitlab-pages']['propagate_correlation_id'] = false
default['gitlab-pages']['log_verbose'] = false
default['gitlab-pages']['access_control'] = false
default['gitlab-pages']['gitlab_id'] = nil
default['gitlab-pages']['gitlab_secret'] = nil
default['gitlab-pages']['auth_redirect_uri'] = nil
default['gitlab-pages']['auth_secret'] = nil
default['gitlab-pages']['auth_scope'] = nil
default['gitlab-pages']['insecure_ciphers'] = false
default['gitlab-pages']['tls_min_version'] = nil
default['gitlab-pages']['tls_max_version'] = nil
default['gitlab-pages']['sentry_enabled'] = false
default['gitlab-pages']['sentry_dsn'] = nil
default['gitlab-pages']['sentry_environment'] = nil
default['gitlab-pages']['headers'] = nil
default['gitlab-pages']['api_secret_key'] = nil
default['gitlab-pages']['gitlab_client_http_timeout'] = nil
default['gitlab-pages']['server_shutdown_timeout'] = nil
default['gitlab-pages']['gitlab_client_jwt_expiry'] = nil
default['gitlab-pages']['env_directory'] = '/opt/gitlab/etc/gitlab-pages/env'
# Serving from zip archives fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab-pages']['zip_cache_expiration'] = nil
default['gitlab-pages']['zip_cache_cleanup'] = nil
default['gitlab-pages']['zip_cache_refresh'] = nil
default['gitlab-pages']['zip_open_timeout'] = nil
default['gitlab-pages']['zip_http_client_timeout'] = nil
# API-based fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab-pages']['gitlab_cache_expiry'] = nil
default['gitlab-pages']['gitlab_cache_refresh'] = nil
default['gitlab-pages']['gitlab_cache_cleanup'] = nil
default['gitlab-pages']['gitlab_retrieval_timeout'] = nil
default['gitlab-pages']['gitlab_retrieval_interval'] = nil
default['gitlab-pages']['gitlab_retrieval_retries'] = nil
# Rate-limiting
default['gitlab-pages']['rate_limit_source_ip'] = nil
default['gitlab-pages']['rate_limit_source_ip_burst'] = nil
default['gitlab-pages']['rate_limit_domain'] = nil
default['gitlab-pages']['rate_limit_domain_burst'] = nil
default['gitlab-pages']['rate_limit_tls_source_ip'] = nil
default['gitlab-pages']['rate_limit_tls_source_ip_burst'] = nil
default['gitlab-pages']['rate_limit_tls_domain'] = nil
default['gitlab-pages']['rate_limit_tls_domain_burst'] = nil
# HTTP Server timeouts
default['gitlab-pages']['server_read_timeout'] = nil
default['gitlab-pages']['server_read_header_timeout'] = nil
default['gitlab-pages']['server_write_timeout'] = nil
default['gitlab-pages']['server_keep_alive'] = nil
# _redirects file fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab-pages']['redirects_max_config_size'] = nil
default['gitlab-pages']['redirects_max_path_segments'] = nil
default['gitlab-pages']['redirects_max_rule_count'] = nil
