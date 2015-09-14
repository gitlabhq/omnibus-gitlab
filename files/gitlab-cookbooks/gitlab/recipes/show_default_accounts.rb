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

account_helper = AccountHelper.new(node)

usernames = account_helper.users

groups = account_helper.groups

puts "Omnibus-gitlab creates user and group accounts to create isolation between processes."
puts "List of default user and group accounts:"
puts ""
puts "Users:"

usernames.each do |user|
  puts user
end
puts ""
puts "Groups:"

groups.each do |group|
  puts group
end

puts ""
puts "**NOTICE**"
puts "If you are creating user and group accounts with a non-default name,"
puts "you will need to add to /etc/gitlab/gitlab.rb configuration options similar to:"
puts account_helper.users_for_gitlab_rb
puts account_helper.groups_for_gitlab_rb
return
