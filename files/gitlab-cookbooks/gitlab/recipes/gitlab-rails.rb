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

ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
known_hosts = File.join(ssh_dir, "known_hosts")
gitlab_app = "gitlab"

gitlab_user = account_helper.gitlab_user
gitlab_group = account_helper.gitlab_group

[
  gitlab_rails_etc_dir,
  gitlab_rails_static_etc_dir,
  gitlab_rails_working_dir,
  gitlab_rails_tmp_dir,
  gitlab_ci_builds_dir,
  node['gitlab']['gitlab-rails']['backup_path'],
  node['gitlab']['gitlab-rails']['gitlab_repository_downloads_path'],
  gitlab_rails_log_dir
].compact.each do |dir_name|
  directory dir_name do
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

directory gitlab_rails_public_uploads_dir do
  owner gitlab_user
  group account_helper.web_server_group
  mode '0750'
  recursive true
end

template File.join(gitlab_rails_static_etc_dir, "gitlab-rails-rc")

dependent_services = []
dependent_services << "service[unicorn]" if OmnibusHelper.should_notify?("unicorn")
dependent_services << "service[sidekiq]" if OmnibusHelper.should_notify?("sidekiq")

redis_not_listening = OmnibusHelper.not_listening?("redis")
postgresql_not_listening = OmnibusHelper.not_listening?("postgresql")

template_symlink File.join(gitlab_rails_dir, "config.ru") do
  link_from File.join(gitlab_rails_source_dir, "config.ru")
  source "gitlab-rails-config.ru.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['unicorn'].to_hash)
  restarts dependent_services
end

template_symlink File.join(gitlab_rails_etc_dir, "secret") do
  link_from File.join(gitlab_rails_source_dir, ".secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services
end

template_symlink File.join(gitlab_rails_etc_dir, "database.yml") do
  link_from File.join(gitlab_rails_source_dir, "config/database.yml")
  source "database.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node['gitlab']['gitlab-rails'].to_hash
  helpers SingleQuoteHelper
  restarts dependent_services
end

if node['gitlab']['gitlab-rails']['redis_port']
  redis_auth = ":#{node['gitlab']['gitlab-rails']['redis_password']}@" if node['gitlab']['gitlab-rails']['redis_password']
  redis_url = "redis://#{redis_auth}#{node['gitlab']['gitlab-rails']['redis_host']}:#{node['gitlab']['gitlab-rails']['redis_port']}"
else
  redis_url = "unix:#{node['gitlab']['gitlab-rails']['redis_socket']}"
end

gitlab_rails = if node['gitlab']['gitlab-ci']['db_key_base']
                 node['gitlab']['gitlab-rails'].to_hash.merge!({ db_key_base: node['gitlab']['gitlab-ci']['db_key_base'] })
               else
                 node['gitlab']['gitlab-rails']
               end

template_symlink File.join(gitlab_rails_etc_dir, "secrets.yml") do
  link_from File.join(gitlab_rails_source_dir, "config/secrets.yml")
  source "secrets.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(gitlab_rails.to_hash)
  helpers SingleQuoteHelper
  restarts dependent_services
end

template_symlink File.join(gitlab_rails_etc_dir, "resque.yml") do
  link_from File.join(gitlab_rails_source_dir, "config/resque.yml")
  source "resque.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(:redis_url => redis_url)
  restarts dependent_services
end

template_symlink File.join(gitlab_rails_etc_dir, "aws.yml") do
  link_from File.join(gitlab_rails_source_dir, "config/aws.yml")
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services

  unless node['gitlab']['gitlab-rails']['aws_enable']
    action :delete
  end
end

template_symlink File.join(gitlab_rails_etc_dir, "smtp_settings.rb") do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/smtp_settings.rb")
  owner "root"
  group "root"
  mode "0644"
  variables(
    node['gitlab']['gitlab-rails'].to_hash.merge(
      :app => gitlab_app
    )
  )
  restarts dependent_services

  unless node['gitlab']['gitlab-rails']['smtp_enable']
    action :delete
  end
end

template_symlink File.join(gitlab_rails_etc_dir, "gitlab.yml") do
  link_from File.join(gitlab_rails_source_dir, "config/gitlab.yml")
  source "gitlab.yml.erb"
  helpers SingleQuoteHelper
  owner "root"
  group "root"
  mode "0644"
  variables(
    node['gitlab']['gitlab-rails'].to_hash.merge(
      gitlab_ci_all_broken_builds: node['gitlab']['gitlab-ci']['gitlab_ci_all_broken_builds'],
      gitlab_ci_add_pusher: node['gitlab']['gitlab-ci']['gitlab_ci_add_pusher'],
      builds_directory: gitlab_ci_builds_dir
    )
  )
  restarts dependent_services
  unless redis_not_listening
    notifies :run, 'execute[clear the gitlab-rails cache]'
  end
end

template_symlink File.join(gitlab_rails_etc_dir, "rack_attack.rb") do
  link_from File.join(gitlab_rails_source_dir, "config/initializers/rack_attack.rb")
  source "rack_attack.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-rails'].to_hash)
  restarts dependent_services
end

link File.join(gitlab_rails_source_dir, ".gitlab_shell_secret") do
  to File.join(gitlab_shell_source_dir, ".gitlab_shell_secret")
end

env_dir File.join(gitlab_rails_static_etc_dir, 'env') do
  variables(
    {
      'HOME' => node['gitlab']['user']['home'],
      'RAILS_ENV' => node['gitlab']['gitlab-rails']['environment'],
    }.merge(node['gitlab']['gitlab-rails']['env'])
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

# Only run `rake db:migrate` when the gitlab-rails version has changed
remote_file File.join(gitlab_rails_dir, 'VERSION') do
  source "file:///opt/gitlab/embedded/service/gitlab-rails/VERSION"
  notifies :run, 'bash[migrate gitlab-rails database]' unless postgresql_not_listening
  notifies :run, 'execute[clear the gitlab-rails cache]' unless redis_not_listening
  dependent_services.each do |sv|
    notifies :restart, sv
  end
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
