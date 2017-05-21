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

default['gitlab']['registry']['enable'] = false
default['gitlab']['registry']['username'] = "registry"
default['gitlab']['registry']['group'] = "registry"
default['gitlab']['registry']['uid'] = nil
default['gitlab']['registry']['gid'] = nil
default['gitlab']['registry']['dir'] = "/var/opt/gitlab/registry"
default['gitlab']['registry']['log_directory'] = "/var/log/gitlab/registry"
default['gitlab']['registry']['log_level'] = "info"
default['gitlab']['registry']['rootcertbundle'] = nil
default['gitlab']['registry']['storage_delete_enabled'] = nil
default['gitlab']['registry']['storage'] = nil
default['gitlab']['registry']['debug_addr'] = nil

####
# Notifications
####
default['gitlab']['registry']['notifications'] = nil
default['gitlab']['registry']['default_notifications_timeout'] = "500ms"
default['gitlab']['registry']['default_notifications_threshold'] = 5
default['gitlab']['registry']['default_notifications_backoff'] = "1s"
default['gitlab']['registry']['default_notifications_headers'] = {}
