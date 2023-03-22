#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
watch_helper = WatchHelper::WatcherConfig.new(node)

# Remove excess watcher configurations and handlers
to_cleanup = watch_helper.excess_handler_scripts
to_cleanup += watch_helper.excess_configs

to_cleanup.each do |f|
  file f do
    action :delete
  end
end

watch_helper.watchers.each do |watcher|
  file watcher.consul_config_file do
    content watcher.consul_config
    owner account_helper.postgresql_user
  end

  # Create/update handler scripts
  template watcher.handler_script do
    source "watcher_scripts/#{watcher.handler_template}"
    variables watcher.template_variables
    mode 0555
  end
end

# Watcher specific settings
pg_service = node['consul']['internal']['postgresql_service_name']
if node['consul']['watchers'].include?(pg_service)
  node.default['pgbouncer']['databases_ini'] = '/var/opt/gitlab/consul/databases.ini'
  node.default['pgbouncer']['databases_json'] = '/var/opt/gitlab/consul/databases.json'
  node.default['pgbouncer']['databases_ini_user'] = 'gitlab-consul'
end
