default['nginx']['enable'] = false
default['nginx']['ha'] = false
default['nginx']['dir'] = "/var/opt/gitlab/nginx"
default['nginx']['log_directory'] = "/var/log/gitlab/nginx"
default['nginx']['error_log_level'] = "error"
default['nginx']['worker_processes'] = [1, node.dig('cpu', 'total').to_i, node.dig('cpu', 'real').to_i].max
default['nginx']['worker_connections'] = 10240
default['nginx']['log_format'] = '$remote_addr - $remote_user [$time_local] "$request_method $filtered_request_uri $server_protocol" $status $body_bytes_sent "$filtered_http_referer" "$http_user_agent" $gzip_ratio' #  NGINX 'combined' format without query strings
default['nginx']['log_format_escape'] = 'default'
default['nginx']['sendfile'] = 'on'
default['nginx']['tcp_nopush'] = 'on'
default['nginx']['tcp_nodelay'] = 'on'
default['nginx']['hide_server_tokens'] = 'off'
default['nginx']['gzip_http_version'] = "1.1"
default['nginx']['gzip_comp_level'] = "2"
default['nginx']['gzip_proxied'] = "no-cache no-store private expired auth"
default['nginx']['gzip_types'] = ["text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json"]
default['nginx']['keepalive_timeout'] = 65
default['nginx']['keepalive_time'] = '1h'
default['nginx']['client_max_body_size'] = 0
default['nginx']['cache_max_size'] = '5000m'
default['nginx']['redirect_http_to_https'] = false
default['nginx']['redirect_http_to_https_port'] = 80
# The following matched paths will set proxy_request_buffering to off
default['nginx']['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
default['nginx']['ssl_client_certificate'] = nil # Most root CA's will be included by default
default['nginx']['ssl_verify_client'] = nil # do not enable 2-way SSL client authentication
default['nginx']['ssl_verify_depth'] = "1" # n/a if ssl_verify_client off
default['nginx']['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
default['nginx']['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
default['nginx']['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['nginx']['ssl_prefer_server_ciphers'] = "off" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['nginx']['ssl_protocols'] = "TLSv1.2 TLSv1.3" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
default['nginx']['ssl_session_cache'] = "shared:SSL:10m"
default['nginx']['ssl_session_tickets'] = "off"
default['nginx']['ssl_session_timeout'] = "1d" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['nginx']['ssl_dhparam'] = nil # Path to dhparam.pem
default['nginx']['ssl_ecdh_curve'] = nil # Specifies a curve for ECDHE ciphers (e.g., 'secp384r1', 'auto')
default['nginx']['ssl_conf_command'] = nil # Array of OpenSSL configuration commands
default['nginx']['ssl_password_file'] = nil
default['nginx']['listen_addresses'] = ['*']
default['nginx']['listen_port'] = nil # override only if you have a reverse proxy
default['nginx']['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP
default['nginx']['custom_gitlab_server_config'] = nil
default['nginx']['custom_nginx_config'] = nil
default['nginx']['proxy_read_timeout'] = 3600
default['nginx']['proxy_connect_timeout'] = 300
default['nginx']['proxy_set_headers'] = {
  "Host" => "$http_host_with_default",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$remote_addr",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade"
}
default['nginx']['proxy_protocol'] = false
default['nginx']['proxy_custom_buffer_size'] = nil
default['nginx']['referrer_policy'] = 'strict-origin-when-cross-origin'
default['nginx']['http2_enabled'] = true
# Cache up to 1GB of HTTP responses from GitLab on disk
default['nginx']['proxy_cache_path'] = 'proxy_cache keys_zone=gitlab:10m max_size=1g levels=1:2'
# Set to 'off' to disable proxy caching.
default['nginx']['proxy_cache'] = 'gitlab'
# Config for the http_realip_module http://nginx.org/en/docs/http/ngx_http_realip_module.html
default['nginx']['real_ip_trusted_addresses'] = [] # Each entry creates a set_real_ip_from directive
default['nginx']['real_ip_header'] = nil
default['nginx']['real_ip_recursive'] = nil
default['nginx']['server_names_hash_bucket_size'] = 64
default['nginx']['default_server_enabled'] = true
# HSTS
default['nginx']['hsts_max_age'] = 63072000 # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['nginx']['hsts_include_subdomains'] = false
# Compression
default['nginx']['gzip_enabled'] = true

# Consul
default['nginx']['consul_service_name'] = 'nginx'
default['nginx']['consul_service_meta'] = nil

###
# Nginx status
###
default['nginx']['status']['enable'] = true
default['nginx']['status']['listen_addresses'] = ['*']
default['nginx']['status']['fqdn'] = "localhost"
default['nginx']['status']['port'] = 8060
default['nginx']['status']['vts_enable'] = true
default['nginx']['status']['options'] = {
  "server_tokens" => "off",
  "access_log" => "off",
  "allow" => "127.0.0.1",
  "deny" => "all",
}

####
# GitLab Pages NGINX
####
default['pages_nginx'] = default['nginx'].dup
default['pages_nginx']['enable'] = true
default['pages_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme"
}

####
# GitLab Registry NGINX
####
default['registry_nginx'] = default['nginx'].dup
default['registry_nginx']['enable'] = true
default['registry_nginx']['https'] = false
default['registry_nginx']['http2_enabled'] = false
default['registry_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme"
}

####
# GitLab KAS NGINX
####
default['gitlab_kas_nginx'] = default['nginx'].dup
default['gitlab_kas_nginx']['enable'] = false
default['gitlab_kas_nginx']['https'] = false
default['gitlab_kas_nginx']['port'] = 80
default['gitlab_kas_nginx']['host'] = "kas.gitlab.example.com"
default['gitlab_kas_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$remote_addr",
  "X-Forwarded-Proto" => "$scheme",
  "X-Forwarded-Scheme" => "$scheme",
  "X-Scheme" => "$scheme",
  "X-Original-Forwarded-For" => "$http_x_forwarded_for"
}
default['gitlab_kas_nginx']['k8s_proxy_connect_timeout'] = "5"
default['gitlab_kas_nginx']['k8s_proxy_send_timeout'] = "60"
default['gitlab_kas_nginx']['k8s_proxy_read_timeout'] = "7200"
default['gitlab_kas_nginx']['k8s_proxy_max_temp_file_size'] = "1024m"
