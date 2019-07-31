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
default['redis']['client_output_buffer_limit_slave'] = "256mb 64mb 60"
default['redis']['client_output_buffer_limit_pubsub'] = "32mb 8mb 60"
default['redis']['save'] = ['900 1', '300 10', '60 10000']

default['redis']['rename_commands'] = nil

####
# Redis Settings for EE
# They are no-op in CE
####
default['redis']['announce_ip'] = nil
default['redis']['announce_port'] = nil
