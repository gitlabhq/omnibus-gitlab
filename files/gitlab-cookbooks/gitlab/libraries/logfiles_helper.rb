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

class LogfilesHelper < AccountHelper
  def default_logdir_ownership # rubocop:disable  Metrics/AbcSize
    # TODO: Make log directory creation in all service recipes use this method
    # instead of directly using `node` values. This will ensure we don't miss
    # to add a service here.
    # https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4606
    {
      'alertmanager' => { username: prometheus_user, group: prometheus_user },
      'consul' => { username: consul_user, group: consul_group, mode: '0755' },
      'crond' => { username: 'root', group: 'root' },
      'geo-logcursor' => { username: gitlab_user, group: gitlab_group },
      'geo-postgresql' => { username: postgresql_user, group: postgresql_group },
      'gitaly' => { username: gitlab_user, group: gitlab_group },
      'gitlab-exporter' => { username: gitlab_user, group: gitlab_group },
      'gitlab-pages' => { username: gitlab_user, group: gitlab_group },
      'gitlab-kas' => { username: gitlab_user, group: gitlab_group },
      'gitlab-rails' => { username: gitlab_user, group: gitlab_group },
      'gitlab-shell' => { username: gitlab_user, group: gitlab_group },
      'gitlab-sshd' => { username: gitlab_user, group: gitlab_group },
      'gitlab-workhorse' => { username: gitlab_user, group: gitlab_group },
      'grafana' => { username: prometheus_user, group: prometheus_group },
      'logrotate' => { username: 'root', group: 'root' },
      'mailroom' => { username: gitlab_user, group: gitlab_group },
      'mattermost' => { username: mattermost_user, group: mattermost_group, mode: '0755' },
      'nginx' => { username: 'root', group: 'root' },
      'node-exporter' => { username: prometheus_user, group: prometheus_group },
      'patroni' => { username: postgresql_user, group: postgresql_group },
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
      'sidekiq' => { username: gitlab_user, group: gitlab_group },
      'storage-check' => { username: gitlab_user, group: gitlab_group },
      'sentinel' => { username: redis_user, group: redis_group },
      'spamcheck' => { username: gitlab_user, group: gitlab_group },
      'spam-classifier' => { username: gitlab_user, group: gitlab_group }
    }
  end

  def service_parent(service)
    available_settings = Gitlab.settings
    setting_name = SettingsDSL::Utils.underscored_form(service)

    raise "Service #{service} is not a valid service." unless available_settings.include?(setting_name)

    available_settings[setting_name][:parent]
  end

  def service_settings(service)
    case service
    when 'spam-classifier'
      # special case for `spam-classifier`
      if parent = service_parent('spamcheck')
        node[parent]['spamcheck']['classifier']
      else
        node['spamcheck']['classifier']
      end
    else
      node_attribute_key = SettingsDSL::Utils.sanitized_key(service)
      if parent = service_parent(service)
        node[parent][node_attribute_key]
      else
        node[node_attribute_key]
      end
    end
  end

  def logdir(service)
    case service
    when 'gitaly'
      service_settings('gitaly')['configuration']['logging']['dir']
    when 'mattermost'
      # mattermost uses 'log_file_directory' instead of 'log_directory'
      service_settings('mattermost')['log_file_directory']
    else
      service_settings(service)['log_directory']
    end
  end

  def logging_options(service)
    node['gitlab']['logging'].to_hash.merge(service_settings(service).to_hash)
  end

  def log_group(service)
    if log_group = service_settings(service)['log_group']
      log_group
    else
      node['gitlab']['logging']['log_group']
    end
  end

  def logdir_owner(service)
    unless default_logdir_ownership.dig(service, :username)
      Chef::Log.warn("#{service} does not have a default set for the log directory user. Setting to root.")
      return 'root'
    end

    default_logdir_ownership[service][:username]
  end

  # Does not change the group on the log_directory unless the service
  # is nginx or a log_group is explicitly configured for the service
  def logdir_group(service)
    if log_directory_group = log_group(service)
      log_directory_group
    elsif service == 'nginx'
      # special case to use web_server_group
      web_server_group
    end
    # implicitly returns nil
  end

  def runit_owner(service)
    # currently hardcoded as 'root'
    'root'
  end

  def logrotate_group(service)
    if configured_log_group = log_group(service)
      configured_log_group
    elsif default_logdir_ownership.key?(service)
      default_logdir_ownership[service][:group] || 'root'
    else
      Chef::Log.warn("#{service} does not have a default group set for logrotate. Setting to root.")
      'root'
    end
  end

  def logdir_mode(service)
    if logdir_group(service)
      # log_group is set - make mode 0750
      '0750'
    elsif default_logdir_ownership.key?(service) && default_logdir_ownership[service][:mode]
      default_logdir_ownership[service][:mode]
    else
      Chef::Log.warn("#{service} does not have a log_group or default logdir mode defined. Setting to 0700.")
      '0700'
    end
  end

  def logging_settings(service)
    service = SettingsDSL::Utils.hyphenated_form(service)
    {
      log_directory: logdir(service),
      log_directory_owner: logdir_owner(service),
      log_directory_group: logdir_group(service),
      log_directory_mode: logdir_mode(service),
      runit_owner: runit_owner(service),
      runit_group: log_group(service),
      logrotate_group: logrotate_group(service),
      options: logging_options(service)
    }
  end

  def logrotate_services_list
    services = {}

    logrotate_services = node['logrotate']['services']
    available_settings = Gitlab.settings

    logrotate_services.each do |svc|
      # In `Gitlab.settings`, settings aren't hyphenated, but use underscores.
      setting_name = svc.tr('-', '_')

      raise "Service #{svc} was specified in logrotate['services'], but is not a valid service." unless available_settings.include?(setting_name)

      services[svc] = logging_settings(svc)
    end

    services
  end
end
