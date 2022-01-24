#
# Copyright:: Copyright (c) 2021 GitLab Inc.
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

data_dir = node['spamcheck']['dir']
sockets_dir = File.join(data_dir, 'sockets')
log_dir = node['spamcheck']['log_directory']
env_dir = node['spamcheck']['env_directory']
config_file = File.join(data_dir, 'config.toml')

classifier_dir = "#{node['package']['install-dir']}/embedded/service/spam-classifier"
preprocessor_dir = File.join(classifier_dir, 'preprocessor')
preprocessor_model_path = File.join(classifier_dir, 'model/issues/tflite/model.tflite')
preprocessor_socket_path = File.join(sockets_dir, 'preprocessor.sock')
preprocessor_log_dir = node['spamcheck']['classifier']['log_directory']

[
  data_dir,
  log_dir,
  sockets_dir,
  preprocessor_log_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
end

template config_file do
  source 'config.toml.erb'
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  variables(node['spamcheck'].to_hash.merge(
              preprocessor_socket_path: preprocessor_socket_path,
              preprocessor_model_path: preprocessor_model_path
            ))
  notifies :restart, 'runit_service[spamcheck]'
end

env_dir env_dir do
  variables node['spamcheck']['env']
  notifies :restart, 'runit_service[spamcheck]' if omnibus_helper.should_notify?('spamcheck')
end

runit_service 'spamcheck' do
  options({
    log_directory: log_dir,
    env_directory: env_dir,
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    config_file: config_file
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['spamcheck'].to_hash)
end

runit_service 'spam-classifier' do
  options({
    log_directory: preprocessor_log_dir,
    env_directory: env_dir,
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    preprocessor_dir: preprocessor_dir,
    sockets_dir: sockets_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['spamcheck'].to_hash)
end
