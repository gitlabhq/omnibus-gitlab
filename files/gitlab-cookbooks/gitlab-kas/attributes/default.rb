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
default['gitlab-kas']['metrics_usage_reporting_period'] = 60
default['gitlab-kas']['dir'] = '/var/opt/gitlab/gitlab-kas'
default['gitlab-kas']['log_directory'] = '/var/log/gitlab/gitlab-kas'
default['gitlab-kas']['env_directory'] = '/opt/gitlab/etc/gitlab-kas/env'
