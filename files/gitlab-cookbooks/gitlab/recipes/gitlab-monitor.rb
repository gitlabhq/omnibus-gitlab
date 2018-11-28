#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
account_helper = AccountHelper.new(node)
redis_helper = RedisHelper.new(node)
gitlab_user = account_helper.gitlab_user
gitlab_monitor_dir = node['gitlab']['gitlab-monitor']['home']
gitlab_monitor_log_dir = node['gitlab']['gitlab-monitor']['log_directory']

directory gitlab_monitor_dir do
  owner gitlab_user
  mode "0755"
  recursive true
end

directory gitlab_monitor_log_dir do
  owner gitlab_user
  mode "0700"
  recursive true
end

connection_string = "dbname=#{node['gitlab']['gitlab-rails']['db_database']} user=#{node['gitlab']['gitlab-rails']['db_username']}"

connection_string += if node['gitlab']['postgresql']['enabled']
                       " host=#{node['gitlab']['postgresql']['dir']}"
                     else
                       " host=#{node['gitlab']['gitlab-rails']['db_host']} port=#{node['gitlab']['gitlab-rails']['db_port']} password=#{node['gitlab']['gitlab-rails']['db_password']}"
                     end

redis_url = redis_helper.redis_url(support_sentinel_groupname: false)

template "#{gitlab_monitor_dir}/gitlab-monitor.yml" do
  source "gitlab-monitor.yml.erb"
  owner gitlab_user
  mode "0600"
  notifies :restart, "service[gitlab-monitor]"
  variables(
    probe_sidekiq: node['gitlab']['gitlab-monitor']['probe_sidekiq'],
    redis_url: redis_url,
    connection_string: connection_string
  )
end

runit_service "gitlab-monitor" do
  options({
    log_directory: gitlab_monitor_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-monitor'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start gitlab-monitor" do
    retries 20
  end
end
