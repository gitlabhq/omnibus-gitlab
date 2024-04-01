unified_mode true

property :socket_group, String
property :dir, String, default: lazy { node['redis']['dir'] }
property :account_helper, default: lazy { AccountHelper.new(node) }, sensitive: true
property :omnibus_helper, default: lazy { OmnibusHelper.new(node) }, sensitive: true
property :redis_helper, default: lazy { NewRedisHelper::Server.new(node) }, sensitive: true
property :runit_sv_timeout, [Integer, nil], default: lazy { node['redis']['runit_sv_timeout'] }
property :logfiles_helper, default: lazy { LogfilesHelper.new(node) }, sensitive: true

action :create do
  logging_settings = new_resource.logfiles_helper.logging_settings('redis')
  account 'user and group for redis' do
    username new_resource.account_helper.redis_user
    uid node['redis']['uid']
    ugid new_resource.account_helper.redis_group
    groupname new_resource.account_helper.redis_group
    gid node['redis']['gid']
    shell node['redis']['shell']
    home node['redis']['home']
    manage node['gitlab']['manage_accounts']['enable']
  end

  group 'Socket group' do
    append true # we need this so we don't remove members
    group_name new_resource.socket_group
  end

  directory new_resource.dir do
    owner new_resource.account_helper.redis_user
    group new_resource.socket_group
    mode "0750"
  end

  # Create log_directory
  directory logging_settings[:log_directory] do
    owner logging_settings[:log_directory_owner]
    mode logging_settings[:log_directory_mode]
    if log_group = logging_settings[:log_directory_group]
      group log_group
    end
    recursive true
  end

  redis_config = ::File.join(new_resource.dir, 'redis.conf')

  if node['redis'].key?('ha')
    if node['redis']['ha']
      node.default['redis']['start_down'] = true
      node.default['redis']['set_replicaof'] = false
    else
      node.default['redis']['start_down'] = false
      node.default['redis']['set_replicaof'] = true unless node['redis']['master']
    end
  end

  template redis_config do
    source "redis.conf.erb"
    owner new_resource.account_helper.redis_user
    mode "0644"
    variables(node['redis'].to_hash)
    notifies :restart, 'runit_service[redis]', :immediately if new_resource.omnibus_helper.should_notify?('redis')
    sensitive true
  end

  open_files_ulimit = node['redis']['open_files_ulimit']

  runit_service 'redis' do
    start_down node['redis']['start_down']
    template_name 'redis'
    options({
      service: 'redis',
      log_directory: logging_settings[:log_directory],
      log_user: logging_settings[:runit_owner],
      log_group: logging_settings[:runit_group],
      open_files_ulimit: open_files_ulimit
    }.merge(new_resource))
    sv_timeout new_resource.runit_sv_timeout
    log_options logging_settings[:options]
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start redis" do
      retries 20
    end
  end

  ruby_block 'warn pending redis restart' do
    block do
      message = <<~MESSAGE
        The version of the running redis service is different than what is installed.
        Please restart redis to start the new version.

        sudo gitlab-ctl restart redis
      MESSAGE
      LoggingHelper.warning(message)
    end
    only_if { node['redis']['startup_delay'].zero? && new_resource.redis_helper.running_version != new_resource.redis_helper.installed_version }
  end
end
