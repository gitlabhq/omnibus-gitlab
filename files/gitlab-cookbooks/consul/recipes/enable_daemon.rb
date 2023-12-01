#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
account_helper = AccountHelper.new(node)
consul_helper = ConsulHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('consul')

runit_service 'consul' do
  options({
            config_dir: node['consul']['config_dir'],
            custom_config_dir: node['consul']['custom_config_dir'],
            config_file: node['consul']['config_file'],
            data_dir: node['consul']['data_dir'],
            dir: node['consul']['dir'],
            log_directory: logging_settings[:log_directory],
            log_user: logging_settings[:runit_user],
            log_group: logging_settings[:runit_group],
            user: node['consul']['username'],
            groupname: node['consul']['group'],
            env_dir: node['consul']['env_directory']
          })
  supervisor_owner account_helper.consul_user
  supervisor_group account_helper.consul_group
  owner account_helper.consul_user
  group account_helper.consul_group
  log_options logging_settings[:options]
end

execute 'reload consul' do
  command '/opt/gitlab/bin/gitlab-ctl hup consul'
  user account_helper.consul_user
  action :nothing
end

ruby_block 'warn pending consul restart' do
  block do
    message = <<~MESSAGE
      The version of the running consul service is different than what is installed.
      Please restart consul to start the new version:

      https://docs.gitlab.com/ee/administration/consul.html#restart-consul
    MESSAGE
    LoggingHelper.warning(message)
  end
  only_if { consul_helper.running_version != consul_helper.installed_version }
end
