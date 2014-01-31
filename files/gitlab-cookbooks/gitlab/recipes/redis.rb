#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

redis_dir = node['gitlab']['redis']['dir']
redis_data_dir = node['gitlab']['redis']['data_dir']
redis_log_dir = node['gitlab']['redis']['log_directory']

user node['gitlab']['redis']['username'] do
  system true
  shell node['gitlab']['redis']['shell']
  home node['gitlab']['redis']['home']
end

directory redis_log_dir do
  owner node['gitlab']['redis']['username']
  recursive true
end

directory redis_dir do
  owner node['gitlab']['redis']['username']
  mode "0700"
end

directory redis_data_dir do
  owner node['gitlab']['redis']['username']
  mode "0700"
  recursive true
end

redis_config = File.join(redis_data_dir, "redis.conf")

template redis_config do
  source "redis.conf.erb"
  owner node['gitlab']['redis']['username']
  mode "0644"
  variables(node['gitlab']['redis'].to_hash)
  notifies :restart, 'service[redis]' if OmnibusHelper.should_notify?("redis")
end

runit_service "redis" do
  down node['gitlab']['redis']['ha']
  control(['t'])
  options({
    :log_directory => redis_log_dir,
    :svlogd_size => node['gitlab']['redis']['svlogd_size'],
    :svlogd_num  => node['gitlab']['redis']['svlogd_num']
  }.merge(params))
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start redis" do
    retries 20
  end
end
