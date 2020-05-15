####
# Prometheus server
####

default['monitoring']['prometheus']['enable'] = false
default['monitoring']['prometheus']['monitor_kubernetes'] = true
default['monitoring']['prometheus']['username'] = 'gitlab-prometheus'
default['monitoring']['prometheus']['group'] = 'gitlab-prometheus'
default['monitoring']['prometheus']['uid'] = nil
default['monitoring']['prometheus']['gid'] = nil
default['monitoring']['prometheus']['shell'] = '/bin/sh'
default['monitoring']['prometheus']['home'] = '/var/opt/gitlab/prometheus'
default['monitoring']['prometheus']['log_directory'] = '/var/log/gitlab/prometheus'
default['monitoring']['prometheus']['env_directory'] = '/opt/gitlab/etc/prometheus/env'
default['monitoring']['prometheus']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['prometheus']['remote_read'] = []
default['monitoring']['prometheus']['remote_write'] = []
default['monitoring']['prometheus']['rules_directory'] = "/var/opt/gitlab/prometheus/rules"
default['monitoring']['prometheus']['scrape_interval'] = 15
default['monitoring']['prometheus']['scrape_timeout'] = 15
default['monitoring']['prometheus']['scrape_configs'] = []
default['monitoring']['prometheus']['listen_address'] = 'localhost:9090'
default['monitoring']['prometheus']['alertmanagers'] = nil

####
# Prometheus Alertmanager
####

default['monitoring']['alertmanager']['enable'] = false
default['monitoring']['alertmanager']['home'] = '/var/opt/gitlab/alertmanager'
default['monitoring']['alertmanager']['log_directory'] = '/var/log/gitlab/alertmanager'
default['monitoring']['alertmanager']['env_directory'] = '/opt/gitlab/etc/alertmanager/env'
default['monitoring']['alertmanager']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['alertmanager']['listen_address'] = 'localhost:9093'
default['monitoring']['alertmanager']['admin_email'] = nil
default['monitoring']['alertmanager']['inhibit_rules'] = []
default['monitoring']['alertmanager']['receivers'] = []
default['monitoring']['alertmanager']['routes'] = []
default['monitoring']['alertmanager']['templates'] = []
default['monitoring']['alertmanager']['global'] = {}

####
# Prometheus Node Exporter
####
default['monitoring']['node-exporter']['enable'] = false
default['monitoring']['node-exporter']['home'] = '/var/opt/gitlab/node-exporter'
default['monitoring']['node-exporter']['log_directory'] = '/var/log/gitlab/node-exporter'
default['monitoring']['node-exporter']['env_directory'] = '/opt/gitlab/etc/node-exporter/env'
default['monitoring']['node-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['node-exporter']['listen_address'] = 'localhost:9100'

####
# Redis exporter
###
default['monitoring']['redis-exporter']['enable'] = false
default['monitoring']['redis-exporter']['log_directory'] = "/var/log/gitlab/redis-exporter"
default['monitoring']['redis-exporter']['env_directory'] = '/opt/gitlab/etc/redis-exporter/env'
default['monitoring']['redis-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['redis-exporter']['listen_address'] = 'localhost:9121'

####
# Postgres exporter
###
default['monitoring']['postgres-exporter']['enable'] = false
default['monitoring']['postgres-exporter']['home'] = '/var/opt/gitlab/postgres-exporter'
default['monitoring']['postgres-exporter']['log_directory'] = "/var/log/gitlab/postgres-exporter"
default['monitoring']['postgres-exporter']['listen_address'] = 'localhost:9187'
default['monitoring']['postgres-exporter']['env_directory'] = '/opt/gitlab/etc/postgres-exporter/env'
default['monitoring']['postgres-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['postgres-exporter']['sslmode'] = nil

####
# Gitlab exporter
###
default['monitoring']['gitlab-exporter']['enable'] = false
default['monitoring']['gitlab-exporter']['log_directory'] = "/var/log/gitlab/gitlab-exporter"
default['monitoring']['gitlab-exporter']['home'] = "/var/opt/gitlab/gitlab-exporter"
default['monitoring']['gitlab-exporter']['listen_address'] = 'localhost'
default['monitoring']['gitlab-exporter']['listen_port'] = '9168'
default['monitoring']['gitlab-exporter']['probe_sidekiq'] = true

# To completely disable prometheus, and all of it's exporters, set to false
default['gitlab']['prometheus-monitoring']['enable'] = true

####
# Grafana
###
default['monitoring']['grafana']['enable'] = false
default['monitoring']['grafana']['log_directory'] = '/var/log/gitlab/grafana'
default['monitoring']['grafana']['home'] = '/var/opt/gitlab/grafana'
default['monitoring']['grafana']['http_addr'] = 'localhost'
default['monitoring']['grafana']['http_port'] = 3000
default['monitoring']['grafana']['admin_password'] = nil
default['monitoring']['grafana']['basic_auth_enabled'] = false
default['monitoring']['grafana']['disable_login_form'] = true
default['monitoring']['grafana']['allow_user_sign_up'] = false
default['monitoring']['grafana']['gitlab_application_id'] = nil
default['monitoring']['grafana']['gitlab_secret'] = nil
default['monitoring']['grafana']['allowed_groups'] = []
default['monitoring']['grafana']['gitlab_auth_sign_up'] = true
default['monitoring']['grafana']['dashboards'] = [
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
default['monitoring']['grafana']['datasources'] = nil
default['monitoring']['grafana']['env_directory'] = '/opt/gitlab/etc/grafana/env'
default['monitoring']['grafana']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['grafana']['metrics_enabled'] = false
default['monitoring']['grafana']['metrics_basic_auth_username'] = nil
default['monitoring']['grafana']['metrics_basic_auth_password'] = nil
default['monitoring']['grafana']['alerting_enabled'] = false
