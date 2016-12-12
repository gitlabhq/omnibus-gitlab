#
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

gitlab_username = account_helper.gitlab_user
gitlab_group = account_helper.gitlab_group
gitlab_home = node['gitlab']['user']['home']

ssh_key_path = File.join(gitlab_home, '.ssh', 'id_rsa')

ssh_keygen ssh_key_path do
  action :create
  owner gitlab_username
  group gitlab_group
  secure_directory true
end
