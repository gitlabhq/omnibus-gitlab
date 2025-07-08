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

default['registry']['enable'] = false
default['registry']['username'] = "registry"
default['registry']['group'] = "registry"
default['registry']['uid'] = nil
default['registry']['gid'] = nil
default['registry']['dir'] = "/var/opt/gitlab/registry"
default['registry']['shell'] = "/usr/sbin/nologin"
default['registry']['log_directory'] = "/var/log/gitlab/registry"
default['registry']['env_directory'] = "/opt/gitlab/etc/registry/env"
default['registry']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
  'GODEBUG' => "tlsmlkem=0",
}
default['registry']['log_level'] = "info"
default['registry']['log_formatter'] = 'text'
default['registry']['rootcertbundle'] = nil
default['registry']['health_storagedriver_enabled'] = true
default['registry']['storage_delete_enabled'] = nil
default['registry']['storage'] = nil
default['registry']['middleware'] = nil
default['registry']['debug_addr'] = nil
default['registry']['validation_enabled'] = false
default['registry']['autoredirect'] = false
default['registry']['compatibility_schema1_enabled'] = false
default['registry']['database']['enabled'] = false
default['registry']['database']['user'] = "registry"
default['registry']['database']['dbname'] = "registry"
default['registry']['database']['port'] = 5432
default['registry']['database']['sslmode'] = "prefer"
default['registry']['gc'] = nil
default['registry']['reporting'] = nil

####
# Notifications
####
default['registry']['notifications'] = nil
default['registry']['default_notifications_timeout'] = "500ms"
default['registry']['default_notifications_threshold'] = 5
default['registry']['default_notifications_maxretries'] = 5
default['registry']['default_notifications_backoff'] = "1s"
default['registry']['default_notifications_headers'] = {}

####
# Redis
####
#
default['registry']['redis'] = {
  'loadbalancing' => {
    'enabled' => false
  }
}
