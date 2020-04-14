#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

require_relative 'account_helper'

class LogrotateHelper < AccountHelper
  def logdir_ownership # rubocop:disable  Metrics/AbcSize
    # TODO: Make log directory creation in all service recipes use this method
    # instead of directly using `node` values. This will ensure we don't miss
    # to add a service here.
    # https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4606
    {
      'alertmanager' => { username: prometheus_user, group: prometheus_user },
      'consul' => { username: consul_user, group: consul_group },
      'crond' => { username: 'root', group: 'root' },
      'geo-logcursor' => { username: gitlab_user, group: gitlab_group },
      'geo-postgresql' => { username: postgresql_user, group: postgresql_group },
      'gitaly' => { username: gitlab_user, group: gitlab_group },
      'gitlab-exporter' => { username: gitlab_user, group: gitlab_group },
      'gitlab-pages' => { username: gitlab_user, group: gitlab_group },
      'gitlab-rails' => { username: gitlab_user, group: gitlab_group },
      'gitlab-shell' => { username: gitlab_user, group: gitlab_group },
      'gitlab-workhorse' => { username: gitlab_user, group: gitlab_group },
      'grafana' => { username: prometheus_user, group: prometheus_group },
      'logrotate' => { username: 'root', group: 'root' },
      'mailroom' => { username: gitlab_user, group: gitlab_group },
      'mattermost' => { username: mattermost_user, group: mattermost_group },
      'nginx' => { username: 'root', group: 'root' },
      'node-exporter' => { username: prometheus_user, group: prometheus_group },
      'pgbouncer' => { username: postgresql_user, group: postgresql_group },
      'pgbouncer-exporter' => { username: postgresql_user, group: postgresql_group },
      'postgres-exporter' => { username: postgresql_user, group: postgresql_group },
      'postgresql' => { username: postgresql_user, group: postgresql_group },
      'praefect' => { username: gitlab_user, group: gitlab_group },
      'prometheus' => { username: prometheus_user, group: prometheus_group },
      'puma' => { username: gitlab_user, group: gitlab_group },
      'redis' => { username: redis_user, group: redis_group },
      'redis-exporter' => { username: redis_user, group: redis_group },
      'registry' => { username: registry_user, group: registry_group },
      'remote-syslog' => { username: 'root', group: 'root' },
      'repmgr' => { username: postgresql_user, group: postgresql_group },
      'sidekiq' => { username: gitlab_user, group: gitlab_group },
      'sidekiq-cluster' => { username: gitlab_user, group: gitlab_group },
      'storage-check' => { username: gitlab_user, group: gitlab_group },
      'unicorn' => { username: gitlab_user, group: gitlab_group },
      'sentinel' => { username: redis_user, group: redis_group }
    }
  end

  def logdir_owner(service)
    unless logdir_ownership.key?(service)
      Chef::Log.warn("#{service} does not have an owner user defined for its log directory. Hence using root.")
      return 'root'
    end

    logdir_ownership[service][:username] || 'root'
  end

  def logdir_group(service)
    unless logdir_ownership.key?(service)
      Chef::Log.warn("#{service} does not have an owner group defined for it log directory. Hence using root.")
      return 'root'
    end

    logdir_ownership[service][:group] || 'root'
  end

  def services_list
    services = {}

    logged_services = node['gitlab']['logrotate']['services']
    available_settings = Gitlab.settings

    logged_services.each do |svc|
      # In `Gitlab.settings`, settings aren't hyphenated, but use underscores.
      setting_name = svc.tr('-', '_')

      raise "Service #{svc} was specified in logrotate['services'], but is not a valid service." unless available_settings.include?(setting_name)

      parent = available_settings[setting_name][:parent]
      if parent
        log_dir = node[parent][svc]['log_directory']
        options = node['gitlab']['logging'].to_hash.merge(node[parent][svc].to_hash)
      else
        log_dir = node[svc]['log_directory']
        options = node['gitlab']['logging'].to_hash.merge(node[svc].to_hash)
      end

      services[svc] = {
        log_directory: log_dir,
        owner: logdir_owner(svc),
        group: logdir_group(svc),
        options: options
      }
    end

    services
  end
end
