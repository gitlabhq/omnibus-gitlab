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

working_dir = node['gitlab_pages']['dir']
log_directory = node['gitlab_pages']['log_directory']
env_directory = node['gitlab_pages']['env_directory']
gitlab_pages_static_etc_dir = "/opt/gitlab/etc/gitlab-pages"
pages_secret_path = File.join(working_dir, ".gitlab_pages_secret")

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

include_recipe 'gitlab::rails_pages_shared_path'

ruby_block "authorize pages with gitlab" do
  block do
    GitlabPages.authorize_with_gitlab
  end

  only_if { node['gitlab_pages']['access_control'] && node['gitlab_pages']['register_as_oauth_app'] }
end

# Options may have changed in the previous step
ruby_block "re-populate GitLab Pages configuration options" do
  block do
    node.consume_attributes(
      { 'gitlab_pages' => Gitlab.hyphenate_config_keys['gitlab_pages'] }
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

template pages_secret_path do
  source "secret_token.erb"
  owner 'root'
  group account_helper.gitlab_group
  mode "0640"
  variables(secret_token: node['gitlab_pages']['api_secret_key'])
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
        pages_external_http: [node['gitlab_pages']['external_http']].flatten.compact,
        pages_external_https: [node['gitlab_pages']['external_https']].flatten.compact,
        pages_external_https_proxyv2: [node['gitlab_pages']['external_https_proxyv2']].flatten.compact,
        pages_headers: [node['gitlab_pages']['headers']].flatten.compact,
        api_secret_key_path: pages_secret_path
      }.merge(node['gitlab_pages'].to_hash)
    end
  )
  notifies :restart, "runit_service[gitlab-pages]"
end

node.default['gitlab_pages']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
}

env_dir env_directory do
  variables node['gitlab_pages']['env']
  notifies :restart, "runit_service[gitlab-pages]" if omnibus_helper.should_notify?('gitlab-pages')
end

runit_service 'gitlab-pages' do
  options({
    log_directory: log_directory,
    env_dir: env_directory,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab_pages'].to_hash)
end
