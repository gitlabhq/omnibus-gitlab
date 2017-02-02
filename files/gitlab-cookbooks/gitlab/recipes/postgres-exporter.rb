#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2016 Gitlab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
account_helper = AccountHelper.new(node)
postgresql_user = account_helper.postgresql_user
postgres_exporter_log_dir = node['gitlab']['postgres-exporter']['log_directory']
postgres_exporter_static_etc_dir = "/opt/gitlab/etc/postgres-exporter"

directory postgres_exporter_log_dir do
  owner postgresql_user
  mode '0700'
  recursive true
end

env_dir File.join(postgres_exporter_static_etc_dir, 'env') do
  variables node['gitlab']['postgres-exporter']['env']
  restarts ["service[postgres-exporter]"]
end

runtime_flags = PrometheusHelper.new(node).flags('postgres-exporter')
runit_service 'postgres-exporter' do
  options({
    log_directory: postgres_exporter_log_dir,
    flags: runtime_flags
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['registry'].to_hash)
end

