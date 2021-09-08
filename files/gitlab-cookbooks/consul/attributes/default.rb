default['consul']['enable'] = false
default['consul']['dir'] = '/var/opt/gitlab/consul'
default['consul']['username'] = 'gitlab-consul'
default['consul']['group'] = 'gitlab-consul'
default['consul']['config_file'] = '/var/opt/gitlab/consul/config.json'
default['consul']['config_dir'] = '/var/opt/gitlab/consul/config.d'
default['consul']['custom_config_dir'] = nil
default['consul']['data_dir'] = '/var/opt/gitlab/consul/data'
default['consul']['log_directory'] = '/var/log/gitlab/consul'
default['consul']['node_name'] = nil
default['consul']['script_directory'] = '/var/opt/gitlab/consul/scripts'
default['consul']['configuration'] = {}
default['consul']['env_directory'] = '/opt/gitlab/etc/consul/env'
default['consul']['env'] = {
  'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
}

# Critical state of service:postgresql indicates a node is not a master
# It does not need to be logged. Health status should be checked from
# the consul cluster.
default['consul']['logging_filters'] = {
  postgresql_warning: "-*agent: Check 'service:postgresql' is now critical"
}
default['consul']['monitoring_service_discovery'] = false
