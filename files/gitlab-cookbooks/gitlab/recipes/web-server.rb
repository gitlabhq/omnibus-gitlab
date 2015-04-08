#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

webserver_username = node['gitlab']['web-server']['username']
webserver_group = node['gitlab']['web-server']['group']
external_webserver_users = node['gitlab']['web-server']['external_users']

# Create the group for the GitLab user
# If external webserver is used, add the external webserver user to
# GitLab webserver group
group webserver_group do
  gid node['gitlab']['web-server']['gid']
  system true
  if external_webserver_users.any? && !node['gitlab']['nginx']['enable']
    append true
    members external_webserver_users
  end
end

# Create the webserver user
user webserver_username do
  shell node['gitlab']['web-server']['shell']
  home node['gitlab']['web-server']['home']
  uid node['gitlab']['web-server']['uid']
  gid webserver_group
  system true
  supports manage_home: false
end
