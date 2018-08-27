####
# Prometheus server
####

default['prometheus']['enable'] = false
default['prometheus']['monitor_kubernetes'] = true
default['prometheus']['username'] = 'gitlab-prometheus'
default['prometheus']['group'] = 'gitlab-prometheus'
default['prometheus']['uid'] = nil
default['prometheus']['gid'] = nil
default['prometheus']['shell'] = '/bin/sh'
default['prometheus']['home'] = '/var/opt/gitlab/prometheus'
default['prometheus']['log_directory'] = '/var/log/gitlab/prometheus'
default['prometheus']['env_directory'] = '/opt/gitlab/etc/prometheus/env'
default['prometheus']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['prometheus']['remote_read'] = []
default['prometheus']['remote_write'] = []
default['prometheus']['rules_directory'] = "/var/opt/gitlab/prometheus/rules"
default['prometheus']['scrape_interval'] = 15
default['prometheus']['scrape_timeout'] = 15
default['prometheus']['scrape_configs'] = []
default['prometheus']['listen_address'] = 'localhost:9090'
default['prometheus']['alertmanagers'] = nil


####
# Grafana
###
default['prometheus']['grafana']['enable'] = false
default['prometheus']['grafana']['log_directory'] = '/var/log/gitlab/grafana'
default['prometheus']['grafana']['home'] = '/var/opt/gitlab/grafana'
default['prometheus']['grafana']['http_addr'] = 'localhost'
default['prometheus']['grafana']['http_port'] = 3000
default['prometheus']['grafana']['admin_password'] = nil
default['prometheus']['grafana']['allow_user_sign_up'] = false
default['prometheus']['grafana']['gitlab_application_id'] = nil
default['prometheus']['grafana']['gitlab_secret'] = nil
default['prometheus']['grafana']['allowed_groups'] = []
default['prometheus']['grafana']['gitlab_auth_sign_up'] = true
default['prometheus']['grafana']['dashboards'] = [
  {
    'name' => 'GitLab Omnibus',
    'orgId' => 1,
    'folder' => 'GitLab Omnibus',
    'type' => 'file',
    'disableDeletion' => true,
    'updateIntervalSeconds' => 600,
    'options' => {
      'path' => '/opt/gitlab/embedded/service/grafana-dashboards',
    },
  }
]
default['prometheus']['grafana']['datasources'] = nil
default['prometheus']['grafana']['env_directory'] = '/opt/gitlab/etc/grafana/env'
default['prometheus']['grafana']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
