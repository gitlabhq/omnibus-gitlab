#
# Copyright:: Copyright (c) 2014 GitLab B.V.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

define :redis_service, socket_group: nil do
  redis_dir = node['redis']['dir']
  redis_log_dir = node['redis']['log_directory']
  redis_user = AccountHelper.new(node).redis_user
  redis_group = AccountHelper.new(node).redis_group
  omnibus_helper = OmnibusHelper.new(node)
  redis_helper = RedisHelper.new(node)

  account 'user and group for redis' do
    username redis_user
    uid node['redis']['uid']
    ugid redis_group
    groupname redis_group
    gid node['redis']['gid']
    shell node['redis']['shell']
    home node['redis']['home']
    manage node['gitlab']['manage-accounts']['enable']
  end

  group 'Socket group' do
    append true # we need this so we don't remove members
    group_name params[:socket_group]
  end

  directory redis_dir do
    owner redis_user
    group params[:socket_group]
    mode "0750"
  end

  directory redis_log_dir do
    owner redis_user
    mode "0700"
  end

  redis_config = File.join(redis_dir, 'redis.conf')
  is_slave = node['redis']['master_ip'] &&
    node['redis']['master_port'] &&
    !node['redis']['master']

  template redis_config do
    source "redis.conf.erb"
    owner redis_user
    mode "0644"
    variables(node['redis'].to_hash.merge({ is_slave: is_slave }))
    notifies :restart, 'runit_service[redis]', :immediately if omnibus_helper.should_notify?('redis')
  end

  runit_service 'redis' do
    down node['redis']['ha']
    template_name 'redis'
    options({
      service: 'redis',
      log_directory: redis_log_dir
    }.merge(params))
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
    only_if { redis_helper.running_version != redis_helper.installed_version }
  end
end
