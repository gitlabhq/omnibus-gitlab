#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

include_recipe 'gitlab::config'

account_helper = AccountHelper.new(node)

usernames = account_helper.users

groups = account_helper.groups

usernames.each do |username|
  account username do
    username username
    action :remove
    manage node['gitlab']['manage-accounts']['enable']
  end
end

groups.each do |group|
  account group do
    groupname group
    action :remove
    manage node['gitlab']['manage-accounts']['enable']
  end
end
