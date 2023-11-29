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
omnibus_helper = OmnibusHelper.new(node)
consul_helper = ConsulHelper.new(node)
mailroom_helper = MailroomHelper.new(node)
redis_helper = RedisHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitlab-rails')

gitlab_rails_source_dir = "/opt/gitlab/embedded/service/gitlab-rails"
gitlab_rails_dir = node['gitlab']['gitlab_rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_rails_static_etc_dir = "/opt/gitlab/etc/gitlab-rails"
gitlab_rails_working_dir = File.join(gitlab_rails_dir, "working")
gitlab_rails_tmp_dir = File.join(gitlab_rails_dir, "tmp")
gitlab_rails_public_uploads_dir = node['gitlab']['gitlab_rails']['uploads_directory']
gitlab_rails_uploads_storage_path = node['gitlab']['gitlab_rails']['uploads_storage_path']
gitlab_ci_dir = node['gitlab']['gitlab_ci']['dir']
gitlab_ci_builds_dir = node['gitlab']['gitlab_ci']['builds_directory']
gitlab_rails_shared_tmp_dir = File.join(node['gitlab']['gitlab_rails']['shared_path'], 'tmp')
gitlab_rails_shared_cache_dir = File.join(node['gitlab']['gitlab_rails']['shared_path'], 'cache')
upgrade_status_dir = File.join(gitlab_rails_dir, "upgrade-status")

# Set path to the private key used for communication between registry and Gitlab.
node.normal['gitlab']['gitlab_rails']['registry_key_path'] = File.join(gitlab_rails_etc_dir, "gitlab-registry.key") if node['gitlab']['gitlab_rails']['registry_key_path'].nil?

gitlab_user = account_helper.gitlab_user
gitlab_group = account_helper.gitlab_group

# Holds git-data, by default one shard at /var/opt/gitlab/git-data
# Can be changed by user using git_data_dirs option
Mash.new(Gitlab['git_data_dirs']).each do |_name, git_data_directory|
  storage_directory git_data_directory['path'] do
    owner gitlab_user
    group gitlab_group
    mode "0700"
  end
end

# Holds git repositories, by default at /var/opt/gitlab/git-data/repositories
# Should not be changed by user. Different permissions to git_data_dir set.
repositories_storages = node['gitlab']['gitlab_rails']['repositories_storages']
repositories_storages.each do |_name, repositories_storage|
  storage_directory repositories_storage['path'] do
    owner gitlab_user
    group gitlab_group
    mode "2770"
  end
end

include_recipe 'gitlab::rails_pages_shared_path'

[
  node['gitlab']['gitlab_rails']['artifacts_path'],
  node['gitlab']['gitlab_rails']['external_diffs_storage_path'],
  node['gitlab']['gitlab_rails']['lfs_storage_path'],
  node['gitlab']['gitlab_rails']['packages_storage_path'],
  node['gitlab']['gitlab_rails']['dependency_proxy_storage_path'],
  node['gitlab']['gitlab_rails']['terraform_state_storage_path'],
  node['gitlab']['gitlab_rails']['ci_secure_files_storage_path'],
  node['gitlab']['gitlab_rails']['encrypted_settings_path'],
  gitlab_rails_public_uploads_dir,
  gitlab_ci_builds_dir,
  gitlab_rails_shared_cache_dir,
  gitlab_rails_shared_tmp_dir
].compact.each do |dir_name|
  storage_directory dir_name do
    owner gitlab_user
    group gitlab_group
    mode '0700'
  end
end

storage_directory gitlab_rails_uploads_storage_path do
  owner gitlab_user
  group gitlab_group
  mode '0700'
  only_if { gitlab_rails_uploads_storage_path != GitlabRails.public_path }
end

[
  gitlab_rails_etc_dir,
  gitlab_rails_static_etc_dir,
  gitlab_rails_working_dir,
  gitlab_rails_tmp_dir,
  node['gitlab']['gitlab_rails']['gitlab_repository_downloads_path'],
  upgrade_status_dir
].compact.each do |dir_name|
  directory "create #{dir_name}" do
    path dir_name
    owner gitlab_user
    mode '0700'
    recursive true
  end
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

storage_directory node['gitlab']['gitlab_rails']['backup_path'] do
  owner gitlab_user
  mode '0700'
  only_if { node['gitlab']['gitlab_rails']['manage_backup_path'] }
end

directory gitlab_rails_dir do
  owner gitlab_user
  mode '0755'
  recursive true
end

directory gitlab_ci_dir do
  owner gitlab_user
  mode '0755'
  recursive true
end

key_file_path = node['gitlab']['gitlab_rails']['registry_key_path']
file key_file_path do
  content node['registry']['internal_key']
  owner gitlab_user
  group gitlab_group
  only_if { node['gitlab']['gitlab_rails']['registry_enabled'] && node['registry']['internal_key'] }
  sensitive true
end

template '/opt/gitlab/etc/gitlab-rails-rc' do
  owner 'root'
  group 'root'
  mode  '0644'
end

dependent_services = []
dependent_services << "runit_service[mailroom]" if node['gitlab']['mailroom']['enable']

node['gitlab']['gitlab_rails']['dependent_services'].each do |name|
  dependent_services << "runit_service[#{name}]" if omnibus_helper.should_notify?(name)
end

dependent_services << "sidekiq_service[sidekiq]" if omnibus_helper.should_notify?('sidekiq')

secret_file = File.join(gitlab_rails_etc_dir, "secret")
secret_symlink = File.join(gitlab_rails_source_dir, ".secret")
otp_key_base = node['gitlab']['gitlab_rails']['otp_key_base']

if File.exist?(secret_file) && File.read(secret_file).chomp != otp_key_base
  message = [
    "The contents of #{secret_file} don't match the value of Gitlab['gitlab_rails']['otp_key_base'] (#{otp_key_base})",
    "Changing the value of the otp_key_base secret will stop two-factor auth working. Please back up #{secret_file} before continuing",
    "For more information, see <https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update/README.md#migrating-legacy-secrets>"
  ]

  raise message.join("\n\n")
end

file secret_symlink do
  action :delete
end

file secret_file do
  action :delete
end

templatesymlink "Create a database.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/database.yml")
  link_to File.join(gitlab_rails_etc_dir, "database.yml")
  source "database.yml.erb"
  owner "root"
  group gitlab_group
  mode "0640"
  variables node['gitlab']['gitlab_rails'].to_hash
  dependent_services.each { |svc| notifies :restart, svc }
  sensitive true
end

templatesymlink "Create a clickhouse.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/click_house.yml")
  link_to File.join(gitlab_rails_etc_dir, "click_house.yml")
  source "click_house.yml.erb"
  owner "root"
  group gitlab_group
  mode "0640"
  variables node['gitlab']['gitlab_rails'].to_hash
  dependent_services.each { |svc| notifies :restart, svc }
  sensitive true
end

redis_url = redis_helper.redis_url
redis_sentinels = node['gitlab']['gitlab_rails']['redis_sentinels']
redis_sentinels_password = node['gitlab']['gitlab_rails']['redis_sentinels_password']
redis_enable_client = node['gitlab']['gitlab_rails']['redis_enable_client']
redis_ssl = node['gitlab']['gitlab_rails']['redis_ssl']
redis_tls_ca_cert_dir = node['gitlab']['gitlab_rails']['redis_tls_ca_cert_dir']
redis_tls_ca_cert_file = node['gitlab']['gitlab_rails']['redis_tls_ca_cert_file']
redis_tls_client_cert_file = node['gitlab']['gitlab_rails']['redis_tls_client_cert_file']
redis_tls_client_key_file = node['gitlab']['gitlab_rails']['redis_tls_client_key_file']
redis_encrypted_settings_file = node['gitlab']['gitlab_rails']['redis_encrypted_settings_file']

templatesymlink "Create a secrets.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/secrets.yml")
  link_to File.join(gitlab_rails_etc_dir, "secrets.yml")
  source "secrets.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  variables('secrets' => { 'production' => {
              'db_key_base' => node['gitlab']['gitlab_rails']['db_key_base'],
              'secret_key_base' => node['gitlab']['gitlab_rails']['secret_key_base'],
              'otp_key_base' => node['gitlab']['gitlab_rails']['otp_key_base'],
              'encrypted_settings_key_base' => node['gitlab']['gitlab_rails']['encrypted_settings_key_base'],
              'openid_connect_signing_key' => node['gitlab']['gitlab_rails']['openid_connect_signing_key'],
              'ci_jwt_signing_key' => node['gitlab']['gitlab_rails']['ci_jwt_signing_key']
            } })
  dependent_services.each { |svc| notifies :restart, svc }
end

templatesymlink "Create a resque.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/resque.yml")
  link_to File.join(gitlab_rails_etc_dir, "resque.yml")
  source "resque.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    redis_url: redis_url,
    redis_sentinels: redis_sentinels,
    redis_sentinels_password: redis_sentinels_password,
    redis_enable_client: redis_enable_client,
    redis_ssl: redis_ssl,
    redis_tls_ca_cert_dir: redis_tls_ca_cert_dir,
    redis_tls_ca_cert_file: redis_tls_ca_cert_file,
    redis_tls_client_cert_file: redis_tls_client_cert_file,
    redis_tls_client_key_file: redis_tls_client_key_file,
    redis_encrypted_settings_file: redis_encrypted_settings_file
  )
  dependent_services.each { |svc| notifies :restart, svc }
  sensitive true
end

templatesymlink "Create an override redis.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/redis.yml")
  link_to File.join(gitlab_rails_etc_dir, "redis.yml")
  source "redis.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(redis_yml: node['gitlab']['gitlab_rails']['redis_yml_override'])
  dependent_services.each { |svc| notifies :restart, svc }
  sensitive true
end

templatesymlink "Create a cable.yml and create a symlink to Rails root" do
  url = node['gitlab']['gitlab_rails']['redis_actioncable_instance']
  sentinels = node['gitlab']['gitlab_rails']['redis_actioncable_sentinels']
  sentinels_password = node['gitlab']['gitlab_rails']['redis_actioncable_sentinels_password']

  if url.nil?
    url = redis_url
    sentinels = redis_sentinels
  end

  link_from File.join(gitlab_rails_source_dir, "config/cable.yml")
  link_to File.join(gitlab_rails_etc_dir, "cable.yml")
  source "cable.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(redis_url: url, redis_sentinels: sentinels, redis_sentinels_password: sentinels_password, redis_enable_client: redis_enable_client)
  dependent_services.each { |svc| notifies :restart, svc }
  sensitive true
end

RedisHelper::REDIS_INSTANCES.each do |instance|
  filename = "redis.#{instance}.yml"
  url = node['gitlab']['gitlab_rails']["redis_#{instance}_instance"]
  sentinels = node['gitlab']['gitlab_rails']["redis_#{instance}_sentinels"]
  sentinels_password = node['gitlab']['gitlab_rails']["redis_#{instance}_sentinels_password"]
  clusters = node['gitlab']['gitlab_rails']["redis_#{instance}_cluster_nodes"]
  username = node['gitlab']['gitlab_rails']["redis_#{instance}_username"]
  password = node['gitlab']['gitlab_rails']["redis_#{instance}_password"]
  redis_ssl = node['gitlab']['gitlab_rails']["redis_#{instance}_ssl"]
  ca_cert_dir = node['gitlab']['gitlab_rails']["redis_#{instance}_tls_ca_cert_dir"]
  ca_cert_file = node['gitlab']['gitlab_rails']["redis_#{instance}_tls_ca_cert_file"]
  certificate_file = node['gitlab']['gitlab_rails']["redis_#{instance}_tls_client_cert_file"]
  key_file = node['gitlab']['gitlab_rails']["redis_#{instance}_tls_client_key_file"]
  instance_encrypted_settings_file = node['gitlab']['gitlab_rails']["redis_#{instance}_encrypted_settings_file"]
  from_filename = File.join(gitlab_rails_source_dir, "config/#{filename}")
  to_filename = File.join(gitlab_rails_etc_dir, filename)

  redis_helper.validate_instance_shard_config(instance)

  templatesymlink "Create a #{filename} and create a symlink to Rails root" do
    link_from from_filename
    link_to to_filename
    source 'resque.yml.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      redis_url: url,
      redis_sentinels: sentinels,
      redis_sentinels_password: sentinels_password,
      redis_enable_client: redis_enable_client,
      cluster_nodes: clusters,
      cluster_username: username,
      cluster_password: password,
      redis_ssl: redis_ssl,
      redis_tls_ca_cert_dir: ca_cert_dir,
      redis_tls_ca_cert_file: ca_cert_file,
      redis_tls_client_cert_file: certificate_file,
      redis_tls_client_key_file: key_file,
      redis_encrypted_settings_file: instance_encrypted_settings_file
    )
    dependent_services.each { |svc| notifies :restart, svc }
    action :delete if url.nil? && clusters.empty?
    sensitive true
  end
end

templatesymlink "Create a smtp_settings.rb and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/smtp_settings.rb")
  link_to File.join(gitlab_rails_etc_dir, "smtp_settings.rb")
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab_rails'].to_hash)
  dependent_services.each { |svc| notifies :restart, svc }

  action :delete unless node['gitlab']['gitlab_rails']['smtp_enable']
end

templatesymlink "Create a gitlab.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/gitlab.yml")
  link_to File.join(gitlab_rails_etc_dir, "gitlab.yml")
  source "gitlab.yml.erb"
  owner "root"
  group gitlab_group
  mode "0640"

  mattermost_host = Gitlab['mattermost_external_url'] || node['gitlab']['gitlab_rails']['mattermost_host']
  has_jh_cookbook = File.exist?('/opt/gitlab/embedded/cookbooks/gitlab-jh')

  variables(
    node['gitlab']['gitlab_rails'].to_hash.merge(
      gitlab_ci_all_broken_builds: node['gitlab']['gitlab_ci']['gitlab_ci_all_broken_builds'],
      gitlab_ci_add_pusher: node['gitlab']['gitlab_ci']['gitlab_ci_add_pusher'],
      builds_directory: gitlab_ci_builds_dir,
      pages_external_http: node['gitlab_pages']['external_http'],
      pages_external_https: node['gitlab_pages']['external_https'],
      pages_external_https_proxyv2: node['gitlab_pages']['external_https_proxyv2'],
      pages_artifacts_server: node['gitlab_pages']['artifacts_server'],
      pages_access_control: node['gitlab_pages']['access_control'],
      pages_object_store_enabled: node['gitlab']['gitlab_rails']['pages_object_store_enabled'],
      pages_object_store_remote_directory: node['gitlab']['gitlab_rails']['pages_object_store_remote_directory'],
      pages_object_store_connection: node['gitlab']['gitlab_rails']['pages_object_store_connection'],
      mattermost_host: mattermost_host,
      mattermost_enabled: node['mattermost']['enable'] || !mattermost_host.nil?,
      sidekiq: node['gitlab']['sidekiq'],
      puma: node['gitlab']['puma'],
      gitlab_shell_authorized_keys_file: node['gitlab']['gitlab_shell']['auth_file'],
      prometheus_available: node['monitoring']['prometheus']['enable'] || !node['gitlab']['gitlab_rails']['prometheus_address'].nil?,
      prometheus_server_address: node['gitlab']['gitlab_rails']['prometheus_address'] || node['monitoring']['prometheus']['listen_address'],
      consul_api_url: node['consul']['enable'] ? consul_helper.api_url : nil,
      mailroom_internal_api_url: mailroom_helper.internal_api_url,
      has_jh_cookbook: has_jh_cookbook
    )
  )
  dependent_services.each { |svc| notifies :restart, svc }
  notifies :run, 'execute[clear the gitlab-rails cache]'
  sensitive true
end

gitlab_workhorse_services = dependent_services
gitlab_workhorse_services += ['runit_service[gitlab-workhorse]'] if omnibus_helper.should_notify?('gitlab-workhorse')

templatesymlink "Create a gitlab_workhorse_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_workhorse_secret")
  link_to File.join(gitlab_rails_etc_dir, 'gitlab_workhorse_secret')
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  variables(secret_token: node['gitlab']['gitlab_workhorse']['secret_token'])
  gitlab_workhorse_services.each { |svc| notifies :restart, svc }
end

templatesymlink "Create a gitlab_shell_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_shell_secret")
  link_to File.join(gitlab_rails_etc_dir, "gitlab_shell_secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  variables(secret_token: node['gitlab']['gitlab_shell']['secret_token'])
  dependent_services.each { |svc| notifies :restart, svc }
  notifies :run, 'bash[Set proper security context on ssh files for selinux]', :delayed if SELinuxHelper.enabled?
end

templatesymlink "Create a gitlab_incoming_email_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_incoming_email_secret")
  link_to File.join(gitlab_rails_etc_dir, "gitlab_incoming_email_secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  variables(secret_token: node['gitlab']['mailroom']['incoming_email_auth_token'])
  only_if { node['gitlab']['mailroom']['incoming_email_auth_token'] }
  dependent_services.each { |svc| notifies :restart, svc }
end

templatesymlink "Create a gitlab_service_desk_email_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_service_desk_email_secret")
  link_to File.join(gitlab_rails_etc_dir, "gitlab_service_desk_email_secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  variables(secret_token: node['gitlab']['mailroom']['service_desk_email_auth_token'])
  only_if { node['gitlab']['mailroom']['service_desk_email_auth_token'] }
  dependent_services.each { |svc| notifies :restart, svc }
end

gitlab_pages_services = dependent_services
gitlab_pages_services += ['runit_service[gitlab-pages]'] if omnibus_helper.should_notify?('gitlab-pages')

templatesymlink "Create a gitlab_pages_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_pages_secret")
  link_to File.join(gitlab_rails_etc_dir, "gitlab_pages_secret")
  source "secret_token.erb"
  owner 'root'
  group 'root'
  mode "0644"
  sensitive true
  variables(secret_token: node['gitlab_pages']['api_secret_key'])
  gitlab_pages_services.each { |svc| notifies :restart, svc }
  only_if { node['gitlab_pages']['api_secret_key'] }
end

gitlab_kas_services = dependent_services
gitlab_kas_services += ['runit_service[gitlab-kas]'] if omnibus_helper.should_notify?('gitlab-kas')

templatesymlink 'Create a gitlab_kas_secret and create a symlink to Rails root' do
  link_from File.join(gitlab_rails_source_dir, '.gitlab_kas_secret')
  link_to File.join(gitlab_rails_etc_dir, 'gitlab_kas_secret')
  source 'secret_token.erb'
  owner 'root'
  group 'root'
  mode '0644'
  sensitive true
  variables(secret_token: node['gitlab_kas']['api_secret_key'])
  gitlab_kas_services.each { |svc| notifies :restart, svc }
  only_if { node['gitlab_kas']['api_secret_key'] }
end

rails_env = {
  'HOME' => node['gitlab']['user']['home'],
  'RAILS_ENV' => node['gitlab']['gitlab_rails']['environment'],
}

# Explicitly deleting relative_urls.rb file and link that was used prior to
# version 9.3.0
link File.join(gitlab_rails_source_dir, "config/initializers/relative_url.rb") do
  action :delete
end

file File.join(gitlab_rails_etc_dir, "relative_url.rb") do
  action :delete
end

gitlab_relative_url = node['gitlab']['gitlab_rails']['gitlab_relative_url']
rails_env['RAILS_RELATIVE_URL_ROOT'] = gitlab_relative_url if gitlab_relative_url

rails_env['BUNDLE_GEMFILE'] = GitlabRailsEnvHelper.bundle_gemfile(gitlab_rails_source_dir)

rails_env['PUMA_WORKER_MAX_MEMORY'] = node['gitlab']['puma']['per_worker_max_memory_mb']

env_dir File.join(gitlab_rails_static_etc_dir, 'env') do
  variables(
    rails_env.merge(node['gitlab']['gitlab_rails']['env'])
  )
  dependent_services.each { |svc| notifies :restart, svc }
end

# replace empty directories in the Git repo with symlinks to /var/opt/gitlab
{
  "/opt/gitlab/embedded/service/gitlab-rails/tmp" => gitlab_rails_tmp_dir,
  "/opt/gitlab/embedded/service/gitlab-rails/public/uploads" => gitlab_rails_public_uploads_dir,
  "/opt/gitlab/embedded/service/gitlab-rails/log" => logging_settings[:log_directory]
}.each do |link_dir, target_dir|
  link link_dir do
    to target_dir
  end
end

legacy_sidekiq_log_file = File.join(logging_settings[:log_directory], 'sidekiq.log')
link legacy_sidekiq_log_file do
  action :delete
  only_if { File.symlink?(legacy_sidekiq_log_file) }
end

# Make structure.sql writable for when we run `rake db:migrate`
file "/opt/gitlab/embedded/service/gitlab-rails/db/structure.sql" do
  owner gitlab_user
end

# Link the VERSION file just for easier administration
remote_file File.join(gitlab_rails_dir, 'VERSION') do
  source "file:///opt/gitlab/embedded/service/gitlab-rails/VERSION"
end

# Only run `rake db:migrate` when the gitlab-rails version has changed
# Or migration failed for some reason
remote_file File.join(gitlab_rails_dir, 'REVISION') do
  source "file:///opt/gitlab/embedded/service/gitlab-rails/REVISION"
end

# If a version of ruby changes restart dependent services. Otherwise, services like
# Puma will fail to reload until restarted
version_file 'Create version file for Rails' do
  version_file_path File.join(gitlab_rails_dir, 'RUBY_VERSION')
  version_check_cmd '/opt/gitlab/embedded/bin/ruby --version'
  dependent_services.each { |svc| notifies :restart, svc }
end

execute "clear the gitlab-rails cache" do
  command "/opt/gitlab/bin/gitlab-rake cache:clear"
  action :nothing
  not_if { omnibus_helper.not_listening?('redis') || !node['gitlab']['gitlab_rails']['rake_cache_clear'] }
end

#
# Up to release 8.6 default config.ru was replaced with omnibus-based one.
# After 8.6 this is not necessery. We can remove this file.
#
file File.join(gitlab_rails_dir, 'config.ru') do
  action :delete
end
