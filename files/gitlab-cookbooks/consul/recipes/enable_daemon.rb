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

runit_service 'consul' do
  options({
            config_dir: node['consul']['config_dir'],
            config_file: node['consul']['config_file'],
            data_dir: node['consul']['data_dir'],
            dir: node['consul']['dir'],
            log_directory: node['consul']['log_directory'],
            user: node['consul']['username'],
            groupname: node['consul']['group'],
            env_dir: node['consul']['env_directory']
          })
  supervisor_owner account_helper.consul_user
  supervisor_group account_helper.consul_group
  owner account_helper.consul_user
  group account_helper.consul_group
  log_options node['gitlab']['logging'].to_hash.merge(node['consul'].to_hash)
end

execute 'reload consul' do
  command '/opt/gitlab/bin/gitlab-ctl hup consul'
  user account_helper.consul_user
  action :nothing
end
