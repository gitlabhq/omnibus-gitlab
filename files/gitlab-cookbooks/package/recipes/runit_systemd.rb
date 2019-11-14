#
# Cookbook Name:: package
# Recipe:: runit_systemd
#
# Copyright 2014 GitLab B.V.
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

require_relative '../libraries/helpers/systemd_helper.rb'

directory '/usr/lib/systemd/system' do
  recursive true
end

tasks_max = node['package']['systemd_tasks_max'] if SystemdHelper.systemd_version >= 227

template "/usr/lib/systemd/system/gitlab-runsvdir.service" do
  mode "0644"
  source "gitlab-runsvdir.service.erb"
  variables(
    tasks_max: tasks_max,
    systemd_after: node['package']['systemd_after'],
    systemd_wanted_by: node['package']['systemd_wanted_by']
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :run, 'execute[systemctl enable gitlab-runsvdir]', :immediately
  notifies :run, 'execute[systemctl start gitlab-runsvdir]', :immediately
end

# Remove old symlink
file "/etc/systemd/system/default.target.wants/gitlab-runsvdir.service" do
  action :delete
end

file "/etc/systemd/system/basic.target.wants/gitlab-runsvdir.service" do
  action :delete
end

execute "systemctl daemon-reload" do
  action :nothing
end

execute "systemctl enable gitlab-runsvdir" do
  action :nothing
end

execute "systemctl start gitlab-runsvdir" do
  action :nothing
end
