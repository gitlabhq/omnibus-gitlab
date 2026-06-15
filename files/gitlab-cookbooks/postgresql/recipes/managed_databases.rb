# Copyright:: Copyright (c) 2026 GitLab Inc.
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

pg_helper = PgHelper.new(node)

ComponentDatabaseRegistry.enabled_entries(node['postgresql']['component_databases']).each do |key, config|
  db_name = config['database'] || key

  postgresql_managed_database_objects db_name do
    config config
    pg_helper pg_helper
    not_if { pg_helper.replica? }
  end
end
