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

default['consul']['logging_filters'] = {}

default['consul']['monitoring_service_discovery'] = false

default['consul']['encryption_key'] = nil
default['consul']['encryption_verify_incoming'] = nil
default['consul']['encryption_verify_outgoing'] = nil

default['consul']['http_port'] = nil
default['consul']['https_port'] = nil

default['consul']['use_tls'] = false
default['consul']['tls_ca_file'] = nil
default['consul']['tls_certificate_file'] = nil
default['consul']['tls_key_file'] = nil
default['consul']['tls_verify_client'] = nil
