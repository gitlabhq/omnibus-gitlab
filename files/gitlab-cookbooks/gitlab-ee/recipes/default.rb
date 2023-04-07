#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

Services.add_services('gitlab-ee', Services::EEServices.list)

include_recipe 'gitlab::default'

%w[
  sentinel
  geo-postgresql
  geo-logcursor
].each do |service|
  node_attribute_key = SettingsDSL::Utils.sanitized_key(service)
  if node['gitlab'][node_attribute_key]['enable']
    include_recipe "gitlab-ee::#{service}"
  else
    include_recipe "gitlab-ee::#{service}_disable"
  end
end

%w(
  consul
  pgbouncer
  patroni
  spamcheck
).each do |service|
  if node[service]['enable']
    include_recipe "#{service}::enable"
  else
    include_recipe "#{service}::disable"
  end
end

rails_enable = node['gitlab']['gitlab-rails']['enable']

# Geo secondary
if node['gitlab']['geo_secondary']['enable']
  if rails_enable
    include_recipe 'gitlab-ee::geo-secondary'
    include_recipe 'gitlab-ee::geo_database_migrations'
  end
else
  include_recipe 'gitlab-ee::geo-secondary_disable'
end

# Suggested Reviewers
include_recipe 'gitlab-ee::suggested_reviewers' if rails_enable

# Create the pgbouncer users
include_recipe 'pgbouncer::user'
