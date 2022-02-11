####
# GitLab Kubernetes Agent Server
####
default['gitlab-kas']['enable'] = false
default['gitlab-kas']['agent_configuration_poll_period'] = 20
default['gitlab-kas']['agent_gitops_poll_period'] = 20
default['gitlab-kas']['agent_gitops_project_info_cache_ttl'] = 300
default['gitlab-kas']['agent_gitops_project_info_cache_error_ttl'] = 60
default['gitlab-kas']['agent_info_cache_ttl'] = 300
default['gitlab-kas']['agent_info_cache_error_ttl'] = 60
default['gitlab-kas']['gitlab_address'] = ''
default['gitlab-kas']['api_secret_key'] = nil
default['gitlab-kas']['listen_address'] = 'localhost:8150'
default['gitlab-kas']['listen_network'] = 'tcp'
default['gitlab-kas']['listen_websocket'] = true
default['gitlab-kas']['certificate_file'] = nil
default['gitlab-kas']['key_file'] = nil
default['gitlab-kas']['internal_api_listen_address'] = 'localhost:8153'
default['gitlab-kas']['internal_api_listen_network'] = 'tcp'
default['gitlab-kas']['internal_api_certificate_file'] = nil
default['gitlab-kas']['internal_api_key_file'] = nil
default['gitlab-kas']['kubernetes_api_listen_address'] = 'localhost:8154'
default['gitlab-kas']['kubernetes_api_certificate_file'] = nil
default['gitlab-kas']['kubernetes_api_key_file'] = nil
default['gitlab-kas']['private_api_secret_key'] = nil
default['gitlab-kas']['private_api_listen_address'] = 'localhost:8155'
default['gitlab-kas']['private_api_listen_network'] = 'tcp'
default['gitlab-kas']['private_api_certificate_file'] = nil
default['gitlab-kas']['private_api_key_file'] = nil
default['gitlab-kas']['metrics_usage_reporting_period'] = 60
default['gitlab-kas']['sentry_dsn'] = nil
default['gitlab-kas']['sentry_environment'] = nil
default['gitlab-kas']['dir'] = '/var/opt/gitlab/gitlab-kas'
default['gitlab-kas']['log_directory'] = '/var/log/gitlab/gitlab-kas'
default['gitlab-kas']['env_directory'] = '/opt/gitlab/etc/gitlab-kas/env'
default['gitlab-kas']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
  'OWN_PRIVATE_API_URL' => 'grpc://localhost:8155'
}
