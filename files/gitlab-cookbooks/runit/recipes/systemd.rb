#
# Cookbook Name:: runit
# Recipe:: systemd
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

directory "/etc/systemd/system/default.target.wants" do
  recursive true
  not_if { ::File.directory?("/etc/systemd/system/default.target.wants") }
end

link "/etc/systemd/system/default.target.wants/gitlab-runsvdir.service" do
  to "/opt/gitlab/embedded/cookbooks/runit/files/default/gitlab-runsvdir.service"
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :run, 'execute[systemctl start gitlab-runsvdir]', :immediately
end

execute "systemctl daemon-reload" do
  action :nothing
end

execute "systemctl start gitlab-runsvdir" do
  action :nothing
end
