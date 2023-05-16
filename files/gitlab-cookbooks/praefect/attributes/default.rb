default['praefect']['enable'] = false
default['praefect']['dir'] = "/var/opt/gitlab/praefect"
default['praefect']['log_directory'] = "/var/log/gitlab/praefect"
default['praefect']['env_directory'] = "/opt/gitlab/etc/praefect/env"
# default['praefect']['env'] is set in ../recipes/enable.rb
default['praefect']['wrapper_path'] = "/opt/gitlab/embedded/bin/gitaly-wrapper"
default['praefect']['auto_migrate'] = true
default['praefect']['consul_service_name'] = 'praefect'
default['praefect']['consul_service_meta'] = nil
default['praefect']['configuration'] = {
  listen_addr: 'localhost:2305',
  prometheus_listen_addr: 'localhost:9652',
  logging: {
    format: 'json',
  },
  auth: {
    transitioning: false
  },
  failover: {
    enabled: true
  }
}
