#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('geo-logcursor')

working_dir = "#{node['package']['install-dir']}/embedded/service/gitlab-rails"
env_directory = node['gitlab']['geo_logcursor']['env_directory']

rails_env = {
  'HOME' => node['gitlab']['user']['home'],
  'RAILS_ENV' => node['gitlab']['gitlab_rails']['environment'],
  'BUNDLE_GEMFILE' => GitlabRailsEnvHelper.bundle_gemfile(working_dir),
}

env_dir env_directory do
  variables(
    rails_env.merge(node['gitlab']['gitlab_rails']['env'])
  )
  notifies :restart, 'runit_service[geo-logcursor]'
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

runit_service 'geo-logcursor' do
  start_down node['gitlab']['geo_logcursor']['ha']
  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    working_dir: working_dir,
    env_dir: env_directory,
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group]
  }.merge(params))
  log_options logging_settings[:options]
end

dependent_services = node['gitlab']['gitlab_rails']['dependent_services']

# This approach was taken to avoid the need to alter the runit service provider
#
execute 'restart geo-logcursor' do
  command '/opt/gitlab/bin/gitlab-ctl restart geo-logcursor'
  action :nothing
  dependent_services.map { |svc| subscribes :run, "runit_service[#{svc}]" }
  notifies :restart, "runit_service[puma]" if omnibus_helper.should_notify?('puma')
end
