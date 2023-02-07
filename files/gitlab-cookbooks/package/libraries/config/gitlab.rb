#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require_relative '../settings_dsl.rb'

module Gitlab
  extend(Mixlib::Config)
  extend(SettingsDSL)

  ## Attributes that don't get passed to the node
  node nil
  roles nil
  edition :ce
  git_data_dirs ConfigMash.new

  ## Roles
  role('application').use { ApplicationRole }
  role('redis_sentinel').use { RedisSentinelRole }
  role('redis_master').use { RedisMasterRole }
  role('redis_replica')
  role('geo_primary',   manage_services: false).use { GeoPrimaryRole }
  role('geo_secondary', manage_services: false).use { GeoSecondaryRole }
  role('monitoring').use { MonitoringRole }
  role('postgres').use { PostgresRole }
  role('pgbouncer').use { PgbouncerRole }
  role('patroni').use { PatroniRole }
  role('consul').use { ConsulRole }
  role('pages').use { PagesRole }
  role('sidekiq').use { SidekiqRole }
  role('spamcheck').use { SpamcheckRole }

  ## Attributes directly on the node
  attribute('package').use { Package }
  attribute('registry',     priority: 20).use { Registry }
  attribute('redis',        priority: 20).use { Redis }
  attribute('postgresql',   priority: 20).use { Postgresql }
  attribute('gitlab_kas',   priority: 20).use { GitlabKas }
  attribute('gitlab_pages', priority: 20).use { GitlabPages }
  attribute('pgbouncer')
  attribute('repmgr')
  attribute('repmgrd')
  attribute('consul').use { Consul }
  attribute('spamcheck')
  attribute('patroni').use { Patroni }
  attribute('gitaly').use { Gitaly }
  attribute('praefect').use { Praefect }
  attribute('mattermost',   priority: 30).use { GitlabMattermost } # Mattermost checks if GitLab is enabled on the same box
  attribute('letsencrypt',  priority: 17).use { LetsEncrypt } # After GitlabRails, but before Registry and Mattermost
  attribute('crond')
  attribute('logrotate')

  # If a new attribute block is added, add it also to the class handling
  # deprecation messages at
  # files/gitlab-cookbooks/package/libraries/deprecations.rb

  # Attributes under node['monitoring']
  attribute_block 'monitoring' do
    # Prometheus needs to be loaded after puma for proper parsing of listen
    # address for rails metrics
    attribute('prometheus',         priority: 21).use { Prometheus }
    attribute('grafana',            priority: 30).use { Grafana }
    attribute('alertmanager',       priority: 30)
    attribute('node_exporter',      priority: 30)
    attribute('redis_exporter',     priority: 30)
    attribute('postgres_exporter',  priority: 30)
    attribute('pgbouncer_exporter', priority: 30)
    attribute('gitlab_exporter',    priority: 30).use { GitlabExporter }
  end

  ## Attributes under node['gitlab']
  attribute_block 'gitlab' do
    # EE attributes
    ee_attribute('geo_postgresql', priority: 20).use { GeoPostgresql }
    ee_attribute('geo_secondary', priority: 20).use { GeoSecondary }
    ee_attribute('geo_logcursor')
    ee_attribute('sentinel').use { Sentinel }
    ee_attribute('suggested_reviewers').use { SuggestedReviewers }

    # Base GitLab attributes
    attribute('gitlab_sshd',      priority: 5)
    attribute('gitlab_shell',     priority: 10).use { GitlabShell } # Parse shell before rails for data dir settings
    attribute('gitlab_rails',     priority: 15).use { GitlabRails } # Parse rails first as others may depend on it
    attribute('gitlab_workhorse', priority: 20).use { GitlabWorkhorse }
    attribute('logging',          priority: 20).use { Logging }
    attribute('unicorn',          priority: 20)
    attribute('puma',             priority: 20).use { Puma }
    attribute('mailroom',         priority: 20).use { IncomingEmail }
    attribute('storage_check',    priority: 30).use { StorageCheck }
    attribute('nginx',            priority: 40).use { Nginx } # Parse nginx last so all external_url are parsed before it
    attribute('external_url',            default: nil)
    attribute('registry_external_url',   default: nil)
    attribute('mattermost_external_url', default: nil)
    attribute('pages_external_url',      default: nil)
    attribute('runtime_dir',             default: nil)
    attribute('git_data_dir',            default: nil)
    attribute('actioncable')
    attribute('bootstrap')
    attribute('omnibus_gitconfig')
    attribute('manage_accounts')
    attribute('manage_storage_directories')
    attribute('user')
    attribute('gitlab_ci')
    attribute('sidekiq').use { Sidekiq }
    attribute('mattermost_nginx')
    attribute('pages_nginx')
    attribute('registry_nginx')
    attribute('remote_syslog')
    attribute('high_availability')
    attribute('web_server')
    attribute('prometheus_monitoring')
  end
end
