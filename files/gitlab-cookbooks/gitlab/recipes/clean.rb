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

usernames = [
              node['gitlab']['user']['username'],
              node['gitlab']['postgresql']['username'],
              node['gitlab']['web-server']['username'],
              node['gitlab']['redis']['username']
            ]

groups = [
            node['gitlab']['user']['group'],
            node['gitlab']['web-server']['group'],
            node['gitlab']['postgresql']['username'], # Group name is same as the username
            node['gitlab']['redis']['username'] # Group name is same as the username
          ]


usernames.each do |username|
  user username do
    action :remove
  end
end

groups.each do |group|
  group group do
    action :remove
  end
end

