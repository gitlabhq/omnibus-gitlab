#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab Inc.
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
require_relative '../../package/libraries/settings_dsl.rb'

# Default location of install-dir is /opt/gitlab/. This path is set during build time.
# DO NOT change this value unless you are building your own GitLab packages
install_dir = node['package']['install-dir']
ENV['PATH'] = "#{install_dir}/bin:#{install_dir}/embedded/bin:#{ENV['PATH']}"

include_recipe 'package::default'

# Setup additional postgresql attributes
include_recipe 'postgresql::directory_locations'

include_recipe "gitlab::gitlab-rails" if node['gitlab']['gitlab_rails']['enable']

include_recipe "gitlab::selinux"

# add trusted certs recipe
include_recipe "gitlab::add_trusted_certs"

# Create dummy services to receive notifications, in case
# the corresponding service recipe is not loaded below.
%w(
  puma
  sidekiq
  mailroom
).each do |dummy|
  service "create a temporary #{dummy} service" do
    service_name dummy
    supports []
  end
end

# Install shell after runit so `gitlab-sshd` comes up
include_recipe "gitlab::gitlab-shell" if node['gitlab']['gitlab_rails']['enable']

# Configure Pre-migration services
# Postgresql depends on Redis because of `rake db:seed_fu`
# Gitaly and/or Praefect must be available before migrations
%w(
  logrotate
  redis
  gitaly
  postgresql
  praefect
  gitlab-kas
).each do |service|
  node_attribute_key = SettingsDSL::Utils.node_attribute_key(service)
  if node[node_attribute_key]['enable']
    include_recipe "#{service}::enable"
  else
    include_recipe "#{service}::disable"
  end
end

if node['gitlab']['gitlab_rails']['enable'] && !(node.key?('pgbouncer') && node['pgbouncer']['enable'])
  include_recipe "gitlab::database_migrations"

  # We need to deal with initial root password only if the DB migrations were
  # applied.
  OmnibusHelper.new(node).print_root_account_details if node['gitlab']['gitlab_rails']['auto_migrate']
end

OmnibusHelper.cleanup_root_password_file

# crond is used by database reindexing and LetsEncrypt auto-renew.  If
# neither are on, we disable crond to prevent stale config files from
# being used.
if node['gitlab']['gitlab_rails']['database_reindexing']['enable'] || (node['letsencrypt']['enable'] && node['letsencrypt']['auto_renew'])
  include_recipe "crond::enable"
else
  include_recipe "crond::disable"
end

# Configure Services
%w[
  puma
  sidekiq
  gitlab-workhorse
  mailroom
  nginx
  remote-syslog
  bootstrap
  storage-check
].each do |service|
  # Temporary until gitlab block has its own nginx attribute -
  # https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8692 For now,
  # nginx lives at node['nginx']; the other services in this loop  still live
  # under node['gitlab'][*].
  enabled = if service == 'nginx'
              node['nginx']['enable']
            else
              node_attribute_key = SettingsDSL::Utils.node_attribute_key(service)
              node["gitlab"][node_attribute_key]["enable"]
            end
  if enabled
    include_recipe "gitlab::#{service}"
  else
    include_recipe "gitlab::#{service}_disable"
  end
end

%w(
  gitlab-pages
  registry
  gitlab-kas
  oak
  letsencrypt
  nginx
).each do |cookbook|
  node_attribute_key = SettingsDSL::Utils.node_attribute_key(cookbook)

  if node[node_attribute_key]["enable"]
    include_recipe "#{cookbook}::enable"
  else
    include_recipe "#{cookbook}::disable"
  end
end

# Always disable the legacy bundled Mattermost runit service. The binary was
# removed in 19.0; this stops the supervised service from a prior install.
# Safe to drop once the `mattermost` deprecation entry expires.
include_recipe 'mattermost::disable'

# Healthcheck runs on every node; the recipe decides per role whether
# to render the rc file (web nodes) or delete a stale one (non-web nodes).
include_recipe "gitlab::gitlab-healthcheck"

# Recipe which handles all prometheus related services
include_recipe "monitoring"

# Recipe for gitlab-backup-cli tool
if node['gitlab']['gitlab_backup_cli']['enable']
  include_recipe "gitlab::gitlab-backup-cli"
else
  include_recipe "gitlab::gitlab-backup-cli_disable"
end

if node['gitlab']['gitlab_rails']['backup_role']
  include_recipe "gitlab::registry_enable_backup_restore_credentials"
else
  include_recipe "gitlab::registry_disable_backup_restore_credentials"
end

if node['gitlab']['gitlab_rails']['database_reindexing']['enable']
  include_recipe 'gitlab::database_reindexing_enable'
else
  include_recipe 'gitlab::database_reindexing_disable'
end
