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

postgresql_dir = node['gitlab']['postgresql']['dir']
postgresql_data_dir = node['gitlab']['postgresql']['data_dir']
postgresql_log_dir = node['gitlab']['postgresql']['log_directory']

user node['gitlab']['postgresql']['username'] do
  system true
  shell node['gitlab']['postgresql']['shell']
  home node['gitlab']['postgresql']['home']
end

directory postgresql_log_dir do
  owner node['gitlab']['postgresql']['username']
  recursive true
end

directory postgresql_dir do
  owner node['gitlab']['postgresql']['username']
  mode "0700"
end

directory postgresql_data_dir do
  owner node['gitlab']['postgresql']['username']
  mode "0700"
  recursive true
end

postgresql_config = File.join(postgresql_data_dir, "postgresql.conf")

template postgresql_config do
  source "postgresql.conf.erb"
  owner node['gitlab']['postgresql']['username']
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[postgresql]' if OmnibusHelper.should_notify?("postgresql")
end

runit_service "postgresql" do
  down node['gitlab']['postgresql']['ha']
  control(['t'])
  options({
    :log_directory => postgresql_log_dir,
    :svlogd_size => node['gitlab']['postgresql']['svlogd_size'],
    :svlogd_num  => node['gitlab']['postgresql']['svlogd_num']
  }.merge(params))
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgresql" do
    retries 20
  end
end
