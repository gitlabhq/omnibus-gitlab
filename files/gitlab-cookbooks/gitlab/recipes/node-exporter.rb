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
node_exporter_user = account_helper.node_exporter_user
node_exporter_log_dir = node['gitlab']['node-exporter']['log_directory']
node_exporter_home = node['gitlab']['node-exporter']['home']
textfile_dir = node['gitlab']['node-exporter']['flags']['collector.textfile.directory']

account "Node exporter user and group" do
  username node_exporter_user
  uid node['gitlab']['node-exporter']['uid']
  ugid node_exporter_user
  groupname node_exporter_user
  gid node['gitlab']['node-exporter']['gid']
  shell node['gitlab']['node-exporter']['shell']
  manage node['gitlab']['manage-accounts']['enable']
end

directory node_exporter_log_dir do
  owner node_exporter_user
  mode "0700"
  recursive true
end

directory textfile_dir  do
  owner node_exporter_user
  mode "0755"
  recursive true
end

runit_service "node-exporter" do
  options({
    :log_directory => node_exporter_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['node-exporter'].to_hash)
end

