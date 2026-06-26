# Attributes common to all services are defined in OmnibusGitLab::NginxHelper.default_values method
default['nginx'] = OmnibusGitlab::NginxHelper.new(node).default_values.dup

# Server configuration
default['nginx']['enable'] = false
default['nginx']['ha'] = false
default['nginx']['worker_processes'] = [1, node.dig('cpu', 'total').to_i, node.dig('cpu', 'real').to_i].max
default['nginx']['worker_connections'] = 10240
default['nginx']['log_format'] = '$remote_addr - $remote_user [$time_local] "$request_method $filtered_request_uri $server_protocol" $status $body_bytes_sent "$filtered_http_referer" "$http_user_agent" $gzip_ratio' #  NGINX 'combined' format without query strings
default['nginx']['log_format_escape'] = 'default'
default['nginx']['sendfile'] = 'on'
default['nginx']['tcp_nopush'] = 'on'
default['nginx']['tcp_nodelay'] = 'on'
default['nginx']['hide_server_tokens'] = 'off'
default['nginx']['keepalive_timeout'] = 65
default['nginx']['keepalive_time'] = '1h'
default['nginx']['cache_max_size'] = '5000m'
default['nginx']['custom_nginx_config'] = nil
default['nginx']['proxy_cache_path'] = 'proxy_cache keys_zone=gitlab:10m max_size=1g levels=1:2'
default['nginx']['server_names_hash_bucket_size'] = 64
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
