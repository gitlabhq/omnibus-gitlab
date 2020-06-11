resource_name :sentinel_service

property :config_path, String
property :redis_configuration, Hash
property :sentinel_configuration, Hash
property :logging_configuration, Hash
property :sentinel_service_name, String, default: 'sentinel'

action :enable do
  sentinel_log_dir = new_resource.sentinel_configuration['log_directory']

  redis_user = AccountHelper.new(node).redis_user
  redis_group = AccountHelper.new(node).redis_group

  omnibus_helper = OmnibusHelper.new(node)
  sentinel_helper = SentinelHelper.new(node)

  account 'user and group for sentinel' do
    username redis_user
    uid node['redis']['uid']
    ugid redis_group
    groupname redis_group
    gid node['redis']['gid']
    shell node['redis']['shell']
    home node['redis']['home']
    manage node['gitlab']['manage-accounts']['enable']
  end

  directory new_resource.sentinel_configuration['dir'] do
    owner new_resource.redis_configuration['username']
    group new_resource.redis_configuration['group']
    mode '0750'
  end

  directory sentinel_log_dir do
    owner new_resource.redis_configuration['username']
    mode '0700'
  end

  runit_service new_resource.sentinel_service_name do
    start_down new_resource.redis_configuration['ha']
    template_name new_resource.sentinel_service_name
    options(
      {
        user: new_resource.redis_configuration['username'],
        groupname: new_resource.redis_configuration['group'],
        config_path: new_resource.config_path,
        log_directory: sentinel_log_dir
      }.merge(new_resource)
    )
    log_options new_resource.redis_configuration.to_hash.merge(new_resource.logging_configuration.to_hash)
  end

  template new_resource.config_path do
    source 'sentinel.conf.erb'
    owner new_resource.redis_configuration['username']
    mode '0644'
    variables(
      {
        redis: new_resource.redis_configuration.to_hash,
        sentinel: new_resource.sentinel_configuration.to_hash
      }
    )
    notifies :restart, 'runit_service[sentinel]', :immediately if omnibus_helper.should_notify?('redis')
    only_if { new_resource.config_path }
  end

  ruby_block 'warn pending sentinel restart' do
    block do
      message = <<~MESSAGE
        The version of the running sentinel service is different than what is installed.
        Please restart sentinel to start the new version.

        sudo gitlab-ctl restart sentinel
      MESSAGE
      LoggingHelper.warning(message)
    end
    only_if { sentinel_helper.running_version != sentinel_helper.installed_version }
  end
end

action :disable do
  runit_service new_resource.sentinel_service_name do
    action :disable
  end

  file new_resource.config_path do
    action :delete
  end

  directory new_resource.sentinel_configuration['dir'] do
    action :delete
  end
end
