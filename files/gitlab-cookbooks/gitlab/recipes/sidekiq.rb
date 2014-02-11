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

sidekiq_log_dir = node['gitlab']['sidekiq']['log_directory']

directory sidekiq_log_dir do
  owner node['gitlab']['user']['username']
  mode '0700'
  recursive true
end

runit_service "sidekiq" do
  down node['gitlab']['sidekiq']['ha']
  options({
    :log_directory => sidekiq_log_dir
  }.merge(params))
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start sidekiq" do
    retries 20
  end
end
