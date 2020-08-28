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
pg_helper = PgHelper.new(node)
consul_helper = ConsulHelper.new(node)

file "#{node['consul']['config_dir']}/postgresql_service.json" do
  content consul_helper.postgresql_service_config.to_json
  owner account_helper.consul_user
  notifies :run, 'execute[reload consul]', :delayed
end

include_recipe 'repmgr::consul_user_permissions' if !pg_helper.delegated? && node['repmgr']['master_on_initialization']
