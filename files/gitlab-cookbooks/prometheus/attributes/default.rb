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
# Prometheus Alertmanager
####

default['prometheus']['alertmanager']['enable'] = false
default['prometheus']['alertmanager']['home'] = '/var/opt/gitlab/alertmanager'
default['prometheus']['alertmanager']['log_directory'] = '/var/log/gitlab/alertmanager'
default['prometheus']['alertmanager']['env_directory'] = '/opt/gitlab/etc/alertmanager/env'
default['prometheus']['alertmanager']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['prometheus']['alertmanager']['listen_address'] = 'localhost:9093'
default['prometheus']['alertmanager']['admin_email'] = nil
default['prometheus']['alertmanager']['inhibit_rules'] = []
default['prometheus']['alertmanager']['receivers'] = []
default['prometheus']['alertmanager']['routes'] = []
default['prometheus']['alertmanager']['templates'] = []

####
# Prometheus Node Exporter
####
default['prometheus']['node-exporter']['enable'] = false
default['prometheus']['node-exporter']['home'] = '/var/opt/gitlab/node-exporter'
default['prometheus']['node-exporter']['log_directory'] = '/var/log/gitlab/node-exporter'
default['prometheus']['node-exporter']['env_directory'] = '/opt/gitlab/etc/node-exporter/env'
default['prometheus']['node-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['prometheus']['node-exporter']['listen_address'] = 'localhost:9100'

####
# Redis exporter
###
default['prometheus']['redis-exporter']['enable'] = false
default['prometheus']['redis-exporter']['log_directory'] = "/var/log/gitlab/redis-exporter"
default['prometheus']['redis-exporter']['env_directory'] = '/opt/gitlab/etc/redis-exporter/env'
default['prometheus']['redis-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['prometheus']['redis-exporter']['listen_address'] = 'localhost:9121'

####
# Postgres exporter
###
default['prometheus']['postgres-exporter']['enable'] = false
default['prometheus']['postgres-exporter']['home'] = '/var/opt/gitlab/postgres-exporter'
default['prometheus']['postgres-exporter']['log_directory'] = "/var/log/gitlab/postgres-exporter"
default['prometheus']['postgres-exporter']['listen_address'] = 'localhost:9187'
default['prometheus']['postgres-exporter']['env_directory'] = '/opt/gitlab/etc/postgres-exporter/env'
default['prometheus']['postgres-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}

####
# Gitlab monitor
###
default['prometheus']['gitlab-monitor']['enable'] = false
default['prometheus']['gitlab-monitor']['log_directory'] = "/var/log/gitlab/gitlab-monitor"
default['prometheus']['gitlab-monitor']['home'] = "/var/opt/gitlab/gitlab-monitor"
default['prometheus']['gitlab-monitor']['listen_address'] = 'localhost'
default['prometheus']['gitlab-monitor']['listen_port'] = '9168'
default['prometheus']['gitlab-monitor']['probe_sidekiq'] = true

# To completely disable prometheus, and all of it's exporters, set to false
default['gitlab']['prometheus-monitoring']['enable'] = true

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
