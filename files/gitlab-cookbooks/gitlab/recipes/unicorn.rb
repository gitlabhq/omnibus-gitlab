#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

unless node['gitlab']['unicorn']['worker_processes']
  node.default['gitlab']['unicorn']['worker_processes'] = Unicorn.workers
end

unicorn_service 'unicorn' do
  rails_app 'gitlab-rails'
  user account_helper.gitlab_user
  group account_helper.gitlab_group
end

sysctl "net.core.somaxconn" do
  value node['gitlab']['unicorn']['somaxconn']
end
