####
# Redis
####
default['redis']['enable'] = false
default['redis']['ha'] = false
default['redis']['hz'] = 10
default['redis']['dir'] = "/var/opt/gitlab/redis"
default['redis']['log_directory'] = "/var/log/gitlab/redis"
default['redis']['username'] = "gitlab-redis"
default['redis']['group'] = "gitlab-redis"
default['redis']['uid'] = nil
default['redis']['gid'] = nil
default['redis']['shell'] = "/bin/false"
default['redis']['home'] = "/var/opt/gitlab/redis"
default['redis']['bind'] = '127.0.0.1'
default['redis']['port'] = 0
default['redis']['maxclients'] = "10000"
default['redis']['maxmemory'] = "0"
default['redis']['maxmemory_policy'] = "noeviction"
default['redis']['maxmemory_samples'] = 5
default['redis']['tcp_backlog'] = 511
default['redis']['tcp_timeout'] = 60
default['redis']['tcp_keepalive'] = 300
default['redis']['password'] = nil
default['redis']['unixsocket'] = "/var/opt/gitlab/redis/redis.socket"
default['redis']['unixsocketperm'] = "777"
default['redis']['master'] = true
default['redis']['master_name'] = 'gitlab-redis'
default['redis']['master_ip'] = nil
default['redis']['master_port'] = 6379
default['redis']['master_password'] = nil
default['redis']['client_output_buffer_limit_normal'] = "0 0 0"
default['redis']['client_output_buffer_limit_replica'] = "256mb 64mb 60"
default['redis']['client_output_buffer_limit_pubsub'] = "32mb 8mb 60"
default['redis']['save'] = ['900 1', '300 10', '60 10000']
default['redis']['io_threads'] = 1
default['redis']['io_threads_do_reads'] = false
default['redis']['stop_writes_on_bgsave_error'] = true

default['redis']['rename_commands'] = nil

## TLS settings
default['redis']['tls_port'] = nil
default['redis']['tls_cert_file'] = nil
default['redis']['tls_key_file'] = nil
default['redis']['tls_dh_params_file'] = nil
default['redis']['tls_ca_cert_file'] = "#{node['package']['install-dir']}/embedded/ssl/certs/cacert.pem"
default['redis']['tls_ca_cert_dir'] = "#{node['package']['install-dir']}/embedded/ssl/certs/"
default['redis']['tls_auth_clients'] = 'optional'
default['redis']['tls_replication'] = nil
default['redis']['tls_cluster'] = nil
default['redis']['tls_protocols'] = nil
default['redis']['tls_ciphers'] = nil
default['redis']['tls_ciphersuites'] = nil
default['redis']['tls_prefer_server_ciphers'] = nil
default['redis']['tls_session_caching'] = nil
default['redis']['tls_session_cache_size'] = nil
default['redis']['tls_session_cache_timeout'] = nil

####
# Redis Settings for EE
# They are no-op in CE
####
default['redis']['announce_ip'] = nil
default['redis']['announce_port'] = nil
