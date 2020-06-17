property :socket_group, String
property :dir, String, default: lazy { node['redis']['dir'] }
property :log_dir, String, default: lazy { node['redis']['log_directory'] }
property :account_helper, default: lazy { AccountHelper.new(node) }
property :omnibus_helper, default: lazy { OmnibusHelper.new(node) }
property :redis_helper, default: lazy { RedisHelper.new(node) }

action :create do
  account 'user and group for redis' do
    username new_resource.account_helper.redis_user
    uid node['redis']['uid']
    ugid new_resource.account_helper.redis_group
    groupname new_resource.account_helper.redis_group
    gid node['redis']['gid']
    shell node['redis']['shell']
    home node['redis']['home']
    manage node['gitlab']['manage-accounts']['enable']
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

  directory new_resource.log_dir do
    owner new_resource.account_helper.redis_user
    mode "0700"
  end

  redis_config = ::File.join(new_resource.dir, 'redis.conf')
  is_replica = node['redis']['master_ip'] &&
    node['redis']['master_port'] &&
    !node['redis']['master']

  template redis_config do
    source "redis.conf.erb"
    owner new_resource.account_helper.redis_user
    mode "0644"
    variables(node['redis'].to_hash.merge({ is_replica: is_replica }))
    notifies :restart, 'runit_service[redis]', :immediately if new_resource.omnibus_helper.should_notify?('redis')
  end

  runit_service 'redis' do
    start_down node['redis']['ha']
    template_name 'redis'
    options({
      service: 'redis',
      log_directory: new_resource.log_dir
    }.merge(new_resource))
    log_options node['gitlab']['logging'].to_hash.merge(node['redis'].to_hash)
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
    only_if { new_resource.redis_helper.running_version != new_resource.redis_helper.installed_version }
  end
end
