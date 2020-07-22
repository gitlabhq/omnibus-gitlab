#
# Copyright:: Copyright (c) 2016 GitLab B.V.
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

working_dir = node['gitlab']['gitlab-pages']['dir']
log_directory = node['gitlab']['gitlab-pages']['log_directory']
env_directory = node['gitlab']['gitlab-pages']['env_directory']
gitlab_pages_static_etc_dir = "/opt/gitlab/etc/gitlab-pages"

[
  working_dir,
  log_directory,
  gitlab_pages_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
end

ruby_block "authorize pages with gitlab" do
  block do
    GitlabPages.authorize_with_gitlab
  end

  not_if { node['gitlab']['gitlab-pages']['gitlab_id'] && node['gitlab']['gitlab-pages']['gitlab_secret'] }
  only_if { node['gitlab']['gitlab-pages']['access_control'] }
end

# Options may have changed in the previous step
ruby_block "re-populate GitLab Pages configuration options" do
  block do
    node.consume_attributes(
      { 'gitlab' => { 'gitlab-pages' => Gitlab.hyphenate_config_keys['gitlab']['gitlab-pages'] } }
    )
  end
end

version_file 'Create version file for Gitlab Pages' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/gitlab-pages --version'
  notifies :restart, "runit_service[gitlab-pages]"
end

# Delete old admin.secret file
file File.join(working_dir, "admin.secret") do
  action :delete
end

template File.join(working_dir, ".gitlab_pages_secret") do
  source "secret_token.erb"
  owner 'root'
  group account_helper.gitlab_group
  mode "0640"
  variables(secret_token: node['gitlab']['gitlab-pages']['api_secret_key'])
  notifies :restart, "runit_service[gitlab-pages]"
end

template File.join(working_dir, "gitlab-pages-config") do
  source "gitlab-pages-config.erb"
  owner 'root'
  group account_helper.gitlab_group
  mode "0640"
  variables(
    lazy do
      {
        auth_client_id: node['gitlab']['gitlab-pages']['gitlab_id'],
        auth_client_secret: node['gitlab']['gitlab-pages']['gitlab_secret'],
        auth_redirect_uri: node['gitlab']['gitlab-pages']['auth_redirect_uri'],
        auth_secret: node['gitlab']['gitlab-pages']['auth_secret']
      }
    end
  )
  notifies :restart, "runit_service[gitlab-pages]"
end

node.default['gitlab']['gitlab-pages']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
}

node.default['gitlab']['gitlab-pages']['env']['http_proxy'] = node['gitlab']['gitlab-pages']['http_proxy'] \
  unless node['gitlab']['gitlab-pages']['http_proxy'].nil?

env_dir env_directory do
  variables node['gitlab']['gitlab-pages']['env']
  notifies :restart, "runit_service[gitlab-pages]" if omnibus_helper.should_notify?('gitlab-pages')
end

runit_service 'gitlab-pages' do
  options({
    log_directory: log_directory,
    env_dir: env_directory,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-pages'].to_hash)
end
