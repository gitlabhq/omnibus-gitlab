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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('sidekiq')

sidekiq_service 'sidekiq' do
  user account_helper.gitlab_user
  group account_helper.gitlab_group
  log_directory logging_settings[:log_directory]
  log_directory_mode logging_settings[:log_directory_mode]
  log_directory_owner logging_settings[:log_directory_owner]
  log_directory_group logging_settings[:log_directory_group]
  log_user logging_settings[:runit_owner]
  log_group logging_settings[:runit_group]
end

consul_service node['gitlab']['sidekiq']['consul_service_name'] do
  id 'sidekiq'
  action Prometheus.service_discovery_action
  ip_address node['gitlab']['sidekiq']['listen_address']
  port node['gitlab']['sidekiq']['listen_port']
  reload_service false unless Services.enabled?('consul')
end
