resource_name :sidekiq_service
provides :sidekiq_service

property :rails_app, String, default: 'gitlab-rails'
property :user, default: lazy { node['gitlab']['user']['username'] }
property :group, default: lazy { node['gitlab']['user']['group'] }
property :log_directory, [String, nil], default: nil
property :template_name, String, default: 'sidekiq'

action :enable do
  svc = new_resource.name
  user = new_resource.user
  group = new_resource.group

  metrics_dir = ::File.join(node['gitlab']['runtime-dir'].to_s, "gitlab/#{svc}") unless node['gitlab']['runtime-dir'].nil?

  sidekiq_log_dir = new_resource.log_directory || node['gitlab'][svc]['log_directory']
  directory sidekiq_log_dir do
    owner user
    mode '0700'
    recursive true
  end

  service_options = {
    user: user,
    groupname: group,
    shutdown_timeout: node['gitlab'][svc]['shutdown_timeout'],
    concurrency: node['gitlab'][svc]['concurrency'],
    log_directory: sidekiq_log_dir,
    metrics_dir: metrics_dir,
    clean_metrics_dir: true,
    rails_app: new_resource.rails_app
  }

  runit_service svc do
    start_down node['gitlab'][svc]['ha']
    template_name new_resource.template_name
    options service_options
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][svc].to_hash)
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end

action :restart do
  runit_service new_resource.name do
    action :restart
  end
end
