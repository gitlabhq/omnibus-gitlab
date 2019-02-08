#
# Cookbook Name:: gitlab
# Recipe:: runit
#
# Copyright 2015-2018, GitLab Inc.
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
require 'open3'

if !node['package']['detect_init']
  Chef::Log.info "Skipped selecting an init system because it was explicitly disabled"
elsif File.exist?('/.dockerenv')
  Chef::Log.warn "Skipped selecting an init system because it looks like we are running in a container"
elsif Open3.capture3('/sbin/init --version | grep upstart')[2].success?
  Chef::Log.warn "Selected upstart because /sbin/init --version is showing upstart."
  include_recipe "package::runit_upstart"
elsif Open3.capture3('systemctl | grep "\-\.mount"')[2].success?
  Chef::Log.warn "Selected systemd because systemctl shows .mount units"
  include_recipe "package::runit_systemd"
else
  Chef::Log.warn "Selected sysvinit because it looks like it is not upstart or systemd."
  include_recipe "package::runit_sysvinit"
end
