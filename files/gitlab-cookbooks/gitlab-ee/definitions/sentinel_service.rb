#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

define :sentinel_service, config_path: nil, redis_configuration: {}, sentinel_configuration: {}, logging_configuration: {}, action: :enable do
  redis = params[:redis_configuration]
  sentinel = params[:sentinel_configuration]
  logging = params[:logging_configuration]
  config_path = params[:config_path]

  sentinel_service_name = 'sentinel'
  sentinel_dir = sentinel['dir']
  sentinel_log_dir = sentinel['log_directory']

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

  case params[:action]
  when :enable

    directory sentinel_dir do
      owner redis['username']
      group redis['group']
      mode '0750'
    end

    directory sentinel_log_dir do
      owner redis['username']
      mode '0700'
    end

    runit_service sentinel_service_name do
      start_down redis['ha']
      template_name sentinel_service_name
      options(
        {
          user: redis['username'],
          groupname: redis['group'],
          config_path: config_path,
          log_directory: sentinel_log_dir
        }.merge(params)
      )
      log_options redis.to_hash.merge(logging.to_hash)
    end

    template config_path do
      source 'sentinel.conf.erb'
      owner redis['username']
      mode '0644'
      variables(
        {
          redis: redis.to_hash,
          sentinel: sentinel.to_hash
        }
      )
      notifies :restart, 'runit_service[sentinel]', :immediately if omnibus_helper.should_notify?('redis')
      only_if { config_path }
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

  when :disable
    runit_service sentinel_service_name do
      action :disable
    end

    file config_path do
      action :delete
    end

    directory sentinel['dir'] do
      action :delete
    end
  end
end
