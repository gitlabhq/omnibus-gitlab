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

gitlab_rails_source_dir = "/opt/gitlab/embedded/service/gitlab-rails"
gitlab_shell_source_dir = "/opt/gitlab/embedded/service/gitlab-shell"
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_rails_static_etc_dir = "/opt/gitlab/etc/gitlab-rails"
gitlab_rails_working_dir = File.join(gitlab_rails_dir, "working")
gitlab_rails_tmp_dir = File.join(gitlab_rails_dir, "tmp")
gitlab_rails_public_uploads_dir = node['gitlab']['gitlab-rails']['uploads_directory']
gitlab_rails_log_dir = node['gitlab']['gitlab-rails']['log_directory']
gitlab_ci_dir = node['gitlab']['gitlab-ci']['dir']
gitlab_ci_builds_dir = node['gitlab']['gitlab-ci']['builds_directory']
upgrade_status_dir = File.join(gitlab_rails_dir, "upgrade-status")

# Set path to the private key used for communication between registry and Gitlab.
node.default['gitlab']['gitlab-rails']['registry_key_path'] = File.join(gitlab_rails_etc_dir, "gitlab-registry.key")

ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
known_hosts = File.join(ssh_dir, "known_hosts")

gitlab_user = account_helper.gitlab_user
gitlab_group = account_helper.gitlab_group

# Explicitly try to create directory holding the logs to make sure
# that the directory is created with correct permissions and not fallback
# on umask of the process
directory File.dirname(gitlab_rails_log_dir) do
  owner gitlab_user
  mode '0755'
  recursive true
end

# We create shared_path with 751 allowing other users to enter into the directories
# It's needed, because by default the shared_path is used to store pages which are served by gitlab-www:gitlab-www
storage_directory node['gitlab']['gitlab-rails']['shared_path'] do
  owner gitlab_user
  group account_helper.web_server_group
  mode '0751'
end

[
  node['gitlab']['gitlab-rails']['artifacts_path'],
  node['gitlab']['gitlab-rails']['lfs_storage_path'],
  gitlab_rails_public_uploads_dir,
  gitlab_ci_builds_dir
].compact.each do |dir_name|
  storage_directory dir_name do
    owner gitlab_user
    mode '0700'
  end
end

storage_directory node['gitlab']['gitlab-rails']['pages_path'] do
  owner gitlab_user
  group account_helper.web_server_group
  mode '0750'
end

[
  gitlab_rails_etc_dir,
  gitlab_rails_static_etc_dir,
  gitlab_rails_working_dir,
  gitlab_rails_tmp_dir,
  node['gitlab']['gitlab-rails']['gitlab_repository_downloads_path'],
  upgrade_status_dir,
  gitlab_rails_log_dir
].compact.each do |dir_name|
  directory "create #{dir_name}" do
    path dir_name
    owner gitlab_user
    mode '0700'
    recursive true
  end
end

directory node['gitlab']['gitlab-rails']['backup_path'] do
  owner gitlab_user
  mode '0700'
  recursive true
  only_if { node['gitlab']['gitlab-rails']['manage_backup_path'] }
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

template File.join(gitlab_rails_static_etc_dir, "gitlab-rails-rc")

dependent_services = []
dependent_services << "service[unicorn]" if OmnibusHelper.should_notify?("unicorn")
dependent_services << "service[sidekiq]" if OmnibusHelper.should_notify?("sidekiq")
dependent_services << "service[mailroom]" if node['gitlab']['mailroom']['enable']

redis_not_listening = OmnibusHelper.not_listening?("redis")
postgresql_not_listening = OmnibusHelper.not_listening?("postgresql")

secret_file = File.join(gitlab_rails_etc_dir, "secret")
secret_symlink = File.join(gitlab_rails_source_dir, ".secret")
otp_key_base = node['gitlab']['gitlab-rails']['otp_key_base']

if File.exists?(secret_file) && File.read(secret_file).chomp != otp_key_base
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
  group "root"
  mode "0644"
  variables node['gitlab']['gitlab-rails'].to_hash
  restarts dependent_services
end

redis_url = RedisHelper.new(node).redis_url
redis_sentinels = node['gitlab']['gitlab-rails']['redis_sentinels']

templatesymlink "Create a secrets.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/secrets.yml")
  link_to File.join(gitlab_rails_etc_dir, "secrets.yml")
  source "secrets.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services
end

templatesymlink "Create a resque.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/resque.yml")
  link_to File.join(gitlab_rails_etc_dir, "resque.yml")
  source "resque.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(:redis_url => redis_url, :redis_sentinels => redis_sentinels)
  restarts dependent_services
end

templatesymlink "Create a aws.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/aws.yml")
  link_to File.join(gitlab_rails_etc_dir, "aws.yml")
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services

  unless node['gitlab']['gitlab-rails']['aws_enable']
    action :delete
  end
end

templatesymlink "Create a smtp_settings.rb and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/smtp_settings.rb")
  link_to File.join(gitlab_rails_etc_dir, "smtp_settings.rb")
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services

  unless node['gitlab']['gitlab-rails']['smtp_enable']
    action :delete
  end
end

templatesymlink "Create a relative_url.rb and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/relative_url.rb")
  link_to File.join(gitlab_rails_etc_dir, "relative_url.rb")
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  notifies [:run, 'bash[generate assets]']
  restarts dependent_services

  unless node['gitlab']['gitlab-rails']['gitlab_relative_url']
    action :delete
  end
end

templatesymlink "Create a gitlab.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/gitlab.yml")
  link_to File.join(gitlab_rails_etc_dir, "gitlab.yml")
  source "gitlab.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    node['gitlab']['gitlab-rails'].to_hash.merge(
      gitlab_ci_all_broken_builds: node['gitlab']['gitlab-ci']['gitlab_ci_all_broken_builds'],
      gitlab_ci_add_pusher: node['gitlab']['gitlab-ci']['gitlab_ci_add_pusher'],
      builds_directory: gitlab_ci_builds_dir,
      git_annex_enabled: node['gitlab']['gitlab-shell']['git_annex_enabled'],
      pages_external_http: node['gitlab']['gitlab-pages']['external_http'],
      pages_external_https: node['gitlab']['gitlab-pages']['external_https']
    )
  )
  restarts dependent_services
  notifies [:run, 'execute[clear the gitlab-rails cache]'] unless redis_not_listening
end

templatesymlink "Create a rack_attack.rb and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/rack_attack.rb")
  link_to File.join(gitlab_rails_etc_dir, "rack_attack.rb")
  source "rack_attack.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services
end

gitlab_workhorse_services = dependent_services
gitlab_workhorse_services += ['service[gitlab-workhorse]'] if OmnibusHelper.should_notify?('gitlab-workhorse')

templatesymlink "Create a gitlab_workhorse_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_workhorse_secret")
  link_to File.join(gitlab_rails_etc_dir, 'gitlab_workhorse_secret')
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(secret_token: node['gitlab']['gitlab-workhorse']['secret_token'])
  restarts gitlab_workhorse_services
end

templatesymlink "Create a gitlab_shell_secret and create a symlink to Rails root" do
  link_from File.join(gitlab_rails_source_dir, ".gitlab_shell_secret")
  link_to File.join(gitlab_rails_etc_dir, "gitlab_shell_secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(secret_token: node['gitlab']['gitlab-shell']['secret_token'])
  restarts dependent_services
end

rails_env = {
  'HOME' => node['gitlab']['user']['home'],
  'RAILS_ENV' => node['gitlab']['gitlab-rails']['environment'],
}

if node['gitlab']['gitlab-rails']['enable_jemalloc']
  rails_env.merge!({'LD_PRELOAD' => "/opt/gitlab/embedded/lib/libjemalloc.so"})
end

env_dir File.join(gitlab_rails_static_etc_dir, 'env') do
  variables(
    rails_env.merge(node['gitlab']['gitlab-rails']['env'])
  )
  restarts dependent_services
end

# replace empty directories in the Git repo with symlinks to /var/opt/gitlab
{
  "/opt/gitlab/embedded/service/gitlab-rails/tmp" => gitlab_rails_tmp_dir,
  "/opt/gitlab/embedded/service/gitlab-rails/public/uploads" => gitlab_rails_public_uploads_dir,
  "/opt/gitlab/embedded/service/gitlab-rails/log" => gitlab_rails_log_dir
}.each do |link_dir, target_dir|
  link link_dir do
    to target_dir
  end
end

legacy_sidekiq_log_file = File.join(gitlab_rails_log_dir, 'sidekiq.log')
link legacy_sidekiq_log_file do
  to File.join(node['gitlab']['sidekiq']['log_directory'], 'current')
  not_if { File.exists?(legacy_sidekiq_log_file) }
end

# Make schema.rb writable for when we run `rake db:migrate`
file "/opt/gitlab/embedded/service/gitlab-rails/db/schema.rb" do
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
  notifies :run, 'bash[generate assets]' if node['gitlab']['gitlab-rails']['gitlab_relative_url']
end

# If a version of ruby changes restart unicorn. If not, unicorn will fail to
# reload until restarted
file File.join(gitlab_rails_dir, "RUBY_VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/bin/ruby --version")
  notifies :restart, "service[unicorn]" if OmnibusHelper.should_notify?('unicorn')
end

# We shipped packages with 'chown -R git' below for quite some time. That chown
# was an unnecessary leftover from the manual installation guide; it is better
# to just leave these files owned by root. If we just remove the 'chown git',
# existing installations will keep 'git' as the owner, so we now explicitly
# change the owner to root:root. Once we feel confident that enough versions
# have been shipped we can maybe get rid of this 'chown' at some point.
execute "chown -R root:root /opt/gitlab/embedded/service/gitlab-rails/public"

execute "clear the gitlab-rails cache" do
  command "/opt/gitlab/bin/gitlab-rake cache:clear"
  action :nothing
end

bash "generate assets" do
  code <<-EOS
    set -e
    /opt/gitlab/bin/gitlab-rake assets:clean assets:precompile
    chown -R #{gitlab_user}:#{gitlab_group} #{gitlab_rails_tmp_dir}/cache
  EOS
  # We have to precompile assets as root because of permissions and ownership of files
  environment ({ 'NO_PRIVILEGE_DROP' => 'true', 'USE_DB' => 'false' })
  dependent_services.each do |sv|
    notifies :restart, sv
  end
  action :nothing
end

bitbucket_keys = node['gitlab']['gitlab-rails']['bitbucket']

unless bitbucket_keys.nil?
  execute 'trust bitbucket.org fingerprint' do
    command "echo '#{bitbucket_keys['known_hosts_key']}' >> #{known_hosts}"
    user gitlab_user
    group gitlab_group
    not_if "grep '#{bitbucket_keys['known_hosts_key']}' #{known_hosts}"
  end

  file File.join(ssh_dir, 'bitbucket_rsa') do
    content "#{bitbucket_keys['private_key']}\n"
    owner gitlab_user
    group gitlab_group
    mode 0600
  end

  ssh_config_file = File.join(ssh_dir, 'config')
  bitbucket_host_config = "Host bitbucket.org\n  IdentityFile ~/.ssh/bitbucket_rsa\n  User #{node['gitlab']['user']['username']}"

  execute 'manage config for bitbucket import key' do
    command "echo '#{bitbucket_host_config}' >> #{ssh_config_file}"
    user gitlab_user
    group gitlab_group
    not_if "grep 'IdentityFile ~/.ssh/bitbucket_rsa' #{ssh_config_file}"
  end

  file File.join(ssh_dir, 'bitbucket_rsa.pub') do
    content "#{bitbucket_keys['public_key']}\n"
    owner gitlab_user
    group gitlab_group
    mode 0644
  end
end

#
# Up to release 8.6 default config.ru was replaced with omnibus-based one.
# After 8.6 this is not necessery. We can remove this file.
#
file File.join(gitlab_rails_dir, 'config.ru') do
  action :delete
end
