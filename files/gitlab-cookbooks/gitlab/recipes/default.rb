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

require 'openssl'

# Default location of install-dir is /opt/gitlab/. This path is set during build time.
# DO NOT change this value unless you are building your own GitLab packages
install_dir = node['package']['install-dir']
ENV['PATH'] = "#{install_dir}/bin:#{install_dir}/embedded/bin:#{ENV['PATH']}"

include_recipe 'gitlab::config'

OmnibusHelper.check_deprecations
OmnibusHelper.check_environment
OmnibusHelper.check_locale

directory "/etc/gitlab" do
  owner "root"
  group "root"
  mode "0775"
  only_if { node['gitlab']['manage-storage-directories']['manage_etc'] }
end.run_action(:create)

node.default['gitlab']['bootstrap']['enable'] = false if File.exist?("/var/opt/gitlab/bootstrapped")

directory "Create /var/opt/gitlab" do
  path "/var/opt/gitlab"
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory "Create /var/log/gitlab" do
  path "/var/log/gitlab"
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory "#{install_dir}/embedded/etc" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

template "#{install_dir}/embedded/etc/gitconfig" do
  source "gitconfig-system.erb"
  mode 0755
  variables gitconfig: node['gitlab']['omnibus-gitconfig']['system']
end

# This recipe needs to run before gitlab-rails
# because we add `gitlab-www` user to some groups created by that recipe
include_recipe "gitlab::web-server"

if node['gitlab']['gitlab-rails']['enable']
  include_recipe "gitlab::users"
  include_recipe "gitlab::gitlab-shell"
  include_recipe "gitlab::gitlab-rails"
end

include_recipe "gitlab::selinux"

# add trusted certs recipe
include_recipe "gitlab::add_trusted_certs"

# Create dummy services to receive notifications, in case
# the corresponding service recipe is not loaded below.
%w(
  unicorn
  puma
  actioncable
  sidekiq
  mailroom
).each do |dummy|
  service "create a temporary #{dummy} service" do
    service_name dummy
    supports []
  end
end

# Install our runit instance
include_recipe "package::runit"

# Make global sysctl commands available
include_recipe "package::sysctl"

# Always run the postgresql::bin recipe
# Run before we enable postgresql for postgresql['version'] to take effect
include_recipe 'postgresql::bin'

# Configure Pre-migration services
# Postgresql depends on Redis because of `rake db:seed_fu`
# Gitaly and/or Praefect must be available before migrations
%w(
  redis
  gitaly
  praefect
  postgresql
).each do |service|
  if node[service]['enable']
    include_recipe "#{service}::enable"
  else
    include_recipe "#{service}::disable"
  end
end

include_recipe "gitlab::database_migrations" if node['gitlab']['gitlab-rails']['enable'] && !(node['gitlab'].key?('pgbouncer') && node['gitlab']['pgbouncer']['enable'])

include_recipe "praefect::database_migrations" if node['praefect']['enable'] && node['praefect']['auto_migrate']

# Always create logrotate folders and configs, even if the service is not enabled.
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/508
include_recipe "gitlab::logrotate_folders_and_configs"

# Configure Services
%w[
  unicorn
  puma
  sidekiq
  sidekiq-cluster
  gitlab-workhorse
  mailroom
  nginx
  remote-syslog
  logrotate
  bootstrap
  gitlab-pages
  storage-check
].each do |service|
  if node["gitlab"][service]["enable"]
    include_recipe "gitlab::#{service}"
  else
    include_recipe "gitlab::#{service}_disable"
  end
end

if node['gitlab']['actioncable']['enable'] && !node['gitlab']['actioncable']['in_app']
  include_recipe "gitlab::actioncable"
else
  include_recipe "gitlab::actioncable_disable"
end

%w(
  registry
  mattermost
).each do |service|
  if node[service]["enable"]
    include_recipe "#{service}::enable"
  else
    include_recipe "#{service}::disable"
  end
end
# Configure healthcheck if we have nginx or workhorse enabled
include_recipe "gitlab::gitlab-healthcheck" if node['gitlab']['nginx']['enable'] || node["gitlab"]["gitlab-workhorse"]["enable"]

# Recipe which handles all prometheus related services
include_recipe "monitoring"

if node['letsencrypt']['enable']
  include_recipe 'letsencrypt::enable'
else
  include_recipe 'letsencrypt::disable'
end

OmnibusHelper.is_deprecated_os?

# Report on any deprecations we encountered at the end of the run
# There are three possible exits for a reconfigure run
# 1. Normal chef-client run completion
# 2. chef-client failed due to an exception
# 3. chef-client failed for some other reason
# 1 and 3 are handled below. 2 is handled in our custom exception handler
# defined at files/gitlab-cookbooks/package/libraries/handlers/gitlab.rb
Chef.event_handler do
  on :run_completed do
    OmnibusHelper.on_exit
  end

  on :run_failed do
    OmnibusHelper.on_exit
  end
end
