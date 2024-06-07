####
# GitLab Pages Daemon
####
default['gitlab_pages']['enable'] = false
default['gitlab_pages']['external_http'] = []
default['gitlab_pages']['external_https'] = []
default['gitlab_pages']['external_https_proxyv2'] = []
default['gitlab_pages']['listen_proxy'] = "localhost:8090"
default['gitlab_pages']['gitlab_server'] = nil
default['gitlab_pages']['internal_gitlab_server'] = nil
default['gitlab_pages']['metrics_address'] = nil
default['gitlab_pages']['pages_path'] = nil
default['gitlab_pages']['enable_disk'] = nil
default['gitlab_pages']['domain'] = nil
default['gitlab_pages']['cert'] = nil
default['gitlab_pages']['cert_key'] = nil
default['gitlab_pages']['redirect_http'] = false
default['gitlab_pages']['use_http2'] = true
default['gitlab_pages']['dir'] = "/var/opt/gitlab/gitlab-pages"
default['gitlab_pages']['log_directory'] = "/var/log/gitlab/gitlab-pages"
default['gitlab_pages']['status_uri'] = nil
default['gitlab_pages']['max_connections'] = nil
default['gitlab_pages']['max_uri_length'] = nil
default['gitlab_pages']['log_format'] = "json"
default['gitlab_pages']['artifacts_server'] = true
default['gitlab_pages']['artifacts_server_url'] = nil
default['gitlab_pages']['artifacts_server_timeout'] = 10
default['gitlab_pages']['propagate_correlation_id'] = false
default['gitlab_pages']['log_verbose'] = false
default['gitlab_pages']['access_control'] = false
default['gitlab_pages']['gitlab_id'] = nil
default['gitlab_pages']['gitlab_secret'] = nil
default['gitlab_pages']['auth_redirect_uri'] = nil
default['gitlab_pages']['auth_secret'] = nil
default['gitlab_pages']['auth_scope'] = nil
default['gitlab_pages']['auth_timeout'] = nil
default['gitlab_pages']['auth_cookie_session_timeout'] = nil
default['gitlab_pages']['insecure_ciphers'] = false
default['gitlab_pages']['tls_min_version'] = nil
default['gitlab_pages']['tls_max_version'] = nil
default['gitlab_pages']['sentry_enabled'] = false
default['gitlab_pages']['sentry_dsn'] = nil
default['gitlab_pages']['sentry_environment'] = nil
default['gitlab_pages']['headers'] = nil
default['gitlab_pages']['api_secret_key'] = nil
default['gitlab_pages']['gitlab_client_http_timeout'] = nil
default['gitlab_pages']['server_shutdown_timeout'] = nil
default['gitlab_pages']['gitlab_client_jwt_expiry'] = nil
default['gitlab_pages']['env_directory'] = '/opt/gitlab/etc/gitlab-pages/env'
# Serving from zip archives fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab_pages']['zip_cache_expiration'] = nil
default['gitlab_pages']['zip_cache_cleanup'] = nil
default['gitlab_pages']['zip_cache_refresh'] = nil
default['gitlab_pages']['zip_open_timeout'] = nil
default['gitlab_pages']['zip_http_client_timeout'] = nil
# API-based fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab_pages']['gitlab_cache_expiry'] = nil
default['gitlab_pages']['gitlab_cache_refresh'] = nil
default['gitlab_pages']['gitlab_cache_cleanup'] = nil
default['gitlab_pages']['gitlab_retrieval_timeout'] = nil
default['gitlab_pages']['gitlab_retrieval_interval'] = nil
default['gitlab_pages']['gitlab_retrieval_retries'] = nil
# Rate-limiting
default['gitlab_pages']['rate_limit_source_ip'] = nil
default['gitlab_pages']['rate_limit_source_ip_burst'] = nil
default['gitlab_pages']['rate_limit_domain'] = nil
default['gitlab_pages']['rate_limit_domain_burst'] = nil
default['gitlab_pages']['rate_limit_tls_source_ip'] = nil
default['gitlab_pages']['rate_limit_tls_source_ip_burst'] = nil
default['gitlab_pages']['rate_limit_tls_domain'] = nil
default['gitlab_pages']['rate_limit_tls_domain_burst'] = nil
# HTTP Server timeouts
default['gitlab_pages']['server_read_timeout'] = nil
default['gitlab_pages']['server_read_header_timeout'] = nil
default['gitlab_pages']['server_write_timeout'] = nil
default['gitlab_pages']['server_keep_alive'] = nil
# _redirects file fine grained configuration.
# The recommended default values are set inside GitLab Pages.
default['gitlab_pages']['redirects_max_config_size'] = nil
default['gitlab_pages']['redirects_max_path_segments'] = nil
default['gitlab_pages']['redirects_max_rule_count'] = nil
default['gitlab_pages']['register_as_oauth_app'] = true
# Experimental - Enable namespace in path
default['gitlab_pages']['namespace_in_path'] = false
# Mutual TLS used with GitLab API
default['gitlab_pages']['client_cert'] = nil
default['gitlab_pages']['client_key'] = nil
default['gitlab_pages']['client_ca_certs'] = nil

# Temporarily retain support for `node['gitlab-pages'][*]` usage in
# `/etc/gitlab/gitlab.rb`
# TODO: Remove support in 16.0
default['gitlab-pages'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab_pages'].to_h }, "node['gitlab-pages']", "node['gitlab_pages']")
