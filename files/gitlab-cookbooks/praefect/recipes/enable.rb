#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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
omnibus_helper = OmnibusHelper.new(node)

working_dir = node['praefect']['dir']
log_directory = node['praefect']['log_directory']
env_directory = node['praefect']['env_directory']
wrapper_path = node['praefect']['wrapper_path']
json_logging = node['praefect']['logging_format'].eql?('json')
config_path = File.join(working_dir, "config.toml")

directory working_dir do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

directory log_directory do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

omnibus_helper.is_deprecated_praefect_config?

node.default['praefect']['env'] = {
  # wrapper script parameters
  'GITALY_PID_FILE' => File.join(node['praefect']['dir'], "praefect.pid"),
  'WRAPPER_JSON_LOGGING' => json_logging
}

env_dir env_directory do
  variables node['praefect']['env']
  notifies :restart, "runit_service[praefect]" if omnibus_helper.should_notify?('praefect')
end

template "Create praefect config.toml" do
  path config_path
  source "praefect-config.toml.erb"
  owner "root"
  group account_helper.gitlab_group
  mode "0640"
  variables node['praefect'].to_hash
  notifies :hup, "runit_service[praefect]"
end

runit_service 'praefect' do
  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    working_dir: working_dir,
    env_dir: env_directory,
    wrapper_path: wrapper_path,
    config_path: config_path,
    log_directory: log_directory,
    json_logging: json_logging
  }.merge(params))

  log_options node['gitlab']['logging'].to_hash.merge(node['praefect'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start praefect" do
    retries 20
  end
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/bin/praefect --version")
  notifies :hup, "runit_service[praefect]"
end

consul_service 'praefect' do
  action Prometheus.service_discovery_action
  socket_address node['praefect']['prometheus_listen_addr']
  reload_service false unless node['consul']['enable']
end
