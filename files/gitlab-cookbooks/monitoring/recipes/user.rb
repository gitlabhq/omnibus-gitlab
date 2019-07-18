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
prometheus_user = account_helper.prometheus_user
prometheus_group = account_helper.prometheus_group
prometheus_dir = node['monitoring']['prometheus']['home']

account "Prometheus user and group" do
  username prometheus_user
  uid node['monitoring']['prometheus']['uid']
  ugid prometheus_group
  groupname prometheus_group
  home prometheus_dir
  gid node['monitoring']['prometheus']['gid']
  shell node['monitoring']['prometheus']['shell']
  manage node['gitlab']['manage-accounts']['enable']
end
