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
group = AccountHelper.new(node).gitlab_group

GITLAB_RAILS_SOURCE_DIR = '/opt/gitlab/embedded/service/gitlab-rails'.freeze

exit_log_format = node['gitlab']['mailroom']['exit_log_format']
mailroom_log_dir = node['gitlab']['mailroom']['log_directory']
mail_room_config = File.join(GITLAB_RAILS_SOURCE_DIR, 'config', 'mail_room.yml')

directory mailroom_log_dir do
  owner user
  mode '0700'
  recursive true
end

runit_service 'mailroom' do
  finish true
  options({
    user: user,
    groupname: group,
    log_directory: mailroom_log_dir,
    mail_room_config: mail_room_config,
    exit_log_format: exit_log_format
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['mailroom'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute '/opt/gitlab/bin/gitlab-ctl start mailroom' do
    retries 20
  end
end
