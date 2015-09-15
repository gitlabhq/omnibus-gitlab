#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

package_install_dir = node['package']['install-dir']
gitlab_ci_source_dir = "/opt/gitlab/embedded/service/gitlab-ci"
gitlab_ci_dir = node['gitlab']['gitlab-ci']['dir']
gitlab_ci_home_dir = File.join(gitlab_ci_dir, "home")
gitlab_ci_etc_dir = File.join(gitlab_ci_dir, "etc")
gitlab_ci_static_etc_dir = "/opt/gitlab/etc/gitlab-ci"
gitlab_ci_working_dir = File.join(gitlab_ci_dir, "working")
gitlab_ci_tmp_dir = File.join(gitlab_ci_dir, "tmp")
gitlab_ci_log_dir = node['gitlab']['gitlab-ci']['log_directory']
gitlab_ci_builds_dir = node['gitlab']['gitlab-ci']['builds_directory']

gitlab_ci_user = AccountHelper.new(node).gitlab_ci_user
gitlab_app = "gitlab-ci"

account "GitLab CI user and group" do
  username gitlab_ci_user
  uid node['gitlab']['gitlab-ci']['uid']
  ugid gitlab_ci_user
  groupname gitlab_ci_user
  gid node['gitlab']['gitlab-ci']['gid']
  shell node['gitlab']['gitlab-ci']['shell']
  home gitlab_ci_home_dir
  manage node['gitlab']['manage-accounts']['enable']
end

[
  gitlab_ci_etc_dir,
  gitlab_ci_static_etc_dir,
  gitlab_ci_home_dir,
  gitlab_ci_working_dir,
  gitlab_ci_tmp_dir,
  node['gitlab']['gitlab-ci']['backup_path'],
  gitlab_ci_log_dir,
  gitlab_ci_builds_dir
].compact.each do |dir_name|
  directory dir_name do
    owner gitlab_ci_user
    mode '0700'
    recursive true
  end
end

directory gitlab_ci_dir do
  owner gitlab_ci_user
  mode '0755'
  recursive true
end

template File.join(gitlab_ci_static_etc_dir, "gitlab-ci-rc")

dependent_services = []
dependent_services << "service[ci-unicorn]" if OmnibusHelper.should_notify?("ci-unicorn")
dependent_services << "service[ci-sidekiq]" if OmnibusHelper.should_notify?("ci-sidekiq")

redis_not_listening = OmnibusHelper.not_listening?("redis")
postgresql_not_listening = OmnibusHelper.not_listening?("postgresql")

template_symlink File.join(gitlab_ci_etc_dir, "secret") do
  link_from File.join(gitlab_ci_source_dir, ".secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-ci'].to_hash)
  restarts dependent_services
end

template_symlink File.join(gitlab_ci_etc_dir, "database.yml") do
  link_from File.join(gitlab_ci_source_dir, "config/database.yml")
  source "database.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node['gitlab']['gitlab-ci'].to_hash
  helpers SingleQuoteHelper
  restarts dependent_services
end

template_symlink File.join(gitlab_ci_etc_dir, "secrets.yml") do
  link_from File.join(gitlab_ci_source_dir, "config/secrets.yml")
  source "secrets.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node['gitlab']['gitlab-ci'].to_hash
  helpers SingleQuoteHelper
  restarts dependent_services
end

if node['gitlab']['gitlab-ci']['redis_port']
  redis_url = "redis://#{node['gitlab']['gitlab-ci']['redis_host']}:#{node['gitlab']['gitlab-ci']['redis_port']}"
else
  redis_url = "unix:#{node['gitlab']['gitlab-ci']['redis_socket']}"
end

template_symlink File.join(gitlab_ci_etc_dir, "resque.yml") do
  link_from File.join(gitlab_ci_source_dir, "config/resque.yml")
  source "resque.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(:redis_url => redis_url)
  restarts dependent_services
end

template_symlink File.join(gitlab_ci_etc_dir, "smtp_settings.rb") do
  link_from File.join(gitlab_ci_source_dir, "config/initializers/smtp_settings.rb")
  owner "root"
  group "root"
  mode "0644"
  variables(
    node['gitlab']['gitlab-ci'].to_hash.merge(
      :app => gitlab_app
    )
  )
  restarts dependent_services

  unless node['gitlab']['gitlab-ci']['smtp_enable']
    action :delete
  end
end

unicorn_url = "http://#{node['gitlab']['unicorn']['listen']}:#{node['gitlab']['unicorn']['port']}"

pg_helper = PgHelper.new(node)
database_ready = pg_helper.is_running? && pg_helper.database_exists?(node['gitlab']['gitlab-rails']['db_database'])

gitlab_server = if node['gitlab']['gitlab-ci']['gitlab_server']
                  node['gitlab']['gitlab-ci']['gitlab_server']
                else
                  database_ready ? CiHelper.authorize_with_gitlab(Gitlab['external_url']):{}
                end

template_symlink File.join(gitlab_ci_etc_dir, "application.yml") do
  link_from File.join(gitlab_ci_source_dir, "config/application.yml")
  source "application.yml.erb"
  helpers SingleQuoteHelper
  owner "root"
  group "root"
  mode "0644"
  variables(
    node['gitlab']['gitlab-ci'].to_hash.merge(
      :gitlab_server => gitlab_server
    )
  )
  restarts dependent_services
  unless redis_not_listening
    notifies :run, 'execute[clear the gitlab-ci cache]'
  end
end

env_dir File.join(gitlab_ci_static_etc_dir, 'env') do
  variables(
    {
      'HOME' => gitlab_ci_home_dir,
      'RAILS_ENV' => node['gitlab']['gitlab-ci']['environment'],
    }.merge(node['gitlab']['gitlab-ci']['env'])
  )
  restarts dependent_services
end

# replace empty directories in the Git repo with symlinks to /var/opt/gitlab
{
  "#{package_install_dir}/embedded/service/gitlab-ci/tmp" => gitlab_ci_tmp_dir,
  "#{package_install_dir}/embedded/service/gitlab-ci/log" => gitlab_ci_log_dir,
  "#{package_install_dir}/embedded/service/gitlab-ci/builds" => gitlab_ci_builds_dir
}.each do |link_dir, target_dir|
  link link_dir do
    to target_dir
  end
end

# Create tmp/cache to make 'rake cache:clear' work
directory File.join(gitlab_ci_tmp_dir, 'cache') do
  user gitlab_ci_user
end

# Make schema.rb writable for when we run `rake db:migrate`
file "/opt/gitlab/embedded/service/gitlab-ci/db/schema.rb" do
  owner gitlab_ci_user
end

# Only run `rake db:migrate` when the gitlab-ci version has changed
remote_file File.join(gitlab_ci_dir, 'VERSION') do
  source "file:///opt/gitlab/embedded/service/gitlab-ci/VERSION"
  notifies :run, 'bash[migrate gitlab-ci database]' unless postgresql_not_listening
  notifies :run, 'execute[clear the gitlab-ci cache]' unless redis_not_listening
  dependent_services.each do |sv|
    notifies :restart, sv
  end
end

execute "clear the gitlab-ci cache" do
  command "/opt/gitlab/bin/gitlab-ci-rake cache:clear"
  action :nothing
end
