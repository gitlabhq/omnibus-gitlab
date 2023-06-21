resource_name :sidekiq_service
provides :sidekiq_service

unified_mode true

property :user, default: lazy { node['gitlab']['user']['username'] }
property :group, default: lazy { node['gitlab']['user']['group'] }
property :log_directory, [String, nil], default: nil
property :log_directory_mode, [String, nil], default: nil
property :log_directory_owner, [String, nil], default: nil
property :log_directory_group, [String, nil], default: nil
property :log_user, [String, nil], default: nil
property :log_group, [String, nil], default: nil
property :logfiles_helper, default: lazy { LogfilesHelper.new(node) }, sensitive: true
property :template_name, String, default: 'sidekiq'

action :enable do
  svc = new_resource.name
  user = new_resource.user
  group = new_resource.group

  metrics_dir = ::File.join(node['gitlab']['runtime_dir'].to_s, "gitlab/#{svc}") unless node['gitlab']['runtime_dir'].nil?

  sidekiq_log_dir = new_resource.log_directory
  sidekiq_log_user = new_resource.log_user
  sidekiq_log_group = new_resource.log_group
  sidekiq_log_dir_mode = new_resource.log_directory_mode
  sidekiq_log_dir_group = new_resource.log_directory_group
  sidekiq_log_dir_owner = new_resource.log_directory_owner

  logging_settings = new_resource.logfiles_helper.logging_settings('sidekiq')

  # Create log_directory
  directory sidekiq_log_dir do
    owner sidekiq_log_dir_owner
    mode sidekiq_log_dir_mode
    group sidekiq_log_dir_group if sidekiq_log_dir_group
    recursive true
  end
  service_options = {
    user: user,
    groupname: group,
    shutdown_timeout: node['gitlab'][svc]['shutdown_timeout'],
    concurrency: node['gitlab'][svc]['concurrency'],
    log_directory: sidekiq_log_dir,
    log_user: sidekiq_log_user,
    log_group: sidekiq_log_group,
    metrics_dir: metrics_dir,
    clean_metrics_dir: true,
  }

  runit_service svc do
    start_down node['gitlab'][svc]['ha']
    template_name new_resource.template_name
    options service_options
    log_options logging_settings[:options]
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
