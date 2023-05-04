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

account_helper = AccountHelper.new(node)
user = account_helper.gitlab_user
group = account_helper.gitlab_group
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('mailroom')

GITLAB_RAILS_SOURCE_DIR = '/opt/gitlab/embedded/service/gitlab-rails'.freeze

exit_log_format = node['gitlab']['mailroom']['exit_log_format']
mailroom_working_dir = "#{node['gitlab']['gitlab_rails']['dir']}/working"
mail_room_config = File.join(GITLAB_RAILS_SOURCE_DIR, 'config', 'mail_room.yml')

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

runit_service 'mailroom' do
  finish true
  options({
    user: user,
    groupname: group,
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    mail_room_config: mail_room_config,
    exit_log_format: exit_log_format,
    working_dir: mailroom_working_dir
  }.merge(params))
  log_options logging_settings[:options]
end

if node['gitlab']['mailroom']['incoming_email_auth_token']
  link File.join(mailroom_working_dir, ".gitlab_incoming_email_secret") do
    to File.join(GITLAB_RAILS_SOURCE_DIR, ".gitlab_incoming_email_secret")
  end
end

if node['gitlab']['mailroom']['service_desk_email_auth_token']
  link File.join(mailroom_working_dir, ".gitlab_service_desk_email_secret") do
    to File.join(GITLAB_RAILS_SOURCE_DIR, ".gitlab_service_desk_email_secret")
  end
end

if node['gitlab']['bootstrap']['enable']
  execute '/opt/gitlab/bin/gitlab-ctl start mailroom' do
    retries 20
  end
end
