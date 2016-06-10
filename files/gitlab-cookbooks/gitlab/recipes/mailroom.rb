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

user = AccountHelper.new(node).gitlab_user

mailroom_log_dir = node['gitlab']['mailroom']['log_directory']
mail_room_config = File.join(node['gitlab']['gitlab-rails']['dir'], "etc", "mail_room.yml")

# mail_room reads YAML-embedded ERB files, and this config file loads the GitLab Rails stack.
# See: https://github.com/tpitale/mail_room/commit/d0cb7d2d9ecfb109f62f673dd907673777e04740
# It does NOT work as a cookbook template at the moment.
cookbook_file mail_room_config do
  notifies :restart, 'service[mailroom]'
end

directory mailroom_log_dir do
  owner user
  mode '0700'
  recursive true
end

runit_service 'mailroom' do
  finish_script true
  options({
    :user => user,
    :log_directory => mailroom_log_dir,
    :mail_room_config => mail_room_config
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['mailroom'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start mailroom" do
    retries 20
  end
end
