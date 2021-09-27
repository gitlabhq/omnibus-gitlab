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
account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)

pg_helper = PgHelper.new(node)

gitlab_user = account_helper.gitlab_user
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

gitlab_rails_source_dir = '/opt/gitlab/embedded/service/gitlab-rails'
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")

dependent_services = %w(puma geo-logcursor sidekiq)

templatesymlink 'Create a database_geo.yml and create a symlink to Rails root' do
  link_from File.join(gitlab_rails_source_dir, 'config/database_geo.yml')
  link_to File.join(gitlab_rails_etc_dir, 'database_geo.yml')
  source 'database_geo.yml.erb'
  cookbook 'gitlab'
  owner 'root'
  group account_helper.gitlab_group
  mode '0640'
  variables node['gitlab']['geo-secondary'].to_hash
  notifies :run, 'ruby_block[Restart geo-secondary dependent services]'
end

ruby_block 'Restart geo-secondary dependent services' do
  block do
    dependent_services.each do |svc|
      notifies :restart, omnibus_helper.restart_service_resource(svc) if omnibus_helper.should_notify?(svc)
    end
  end
  action :nothing
end

# Make structure.sql writable for when we run `rake geo:db:migrate`
file '/opt/gitlab/embedded/service/gitlab-rails/ee/db/geo/structure.sql' do
  owner gitlab_user
end

# This is included by postgresql.conf for replication settings in PostgreSQL 12 and higher
if node['postgresql']['enable']
  file pg_helper.geo_config do
    owner postgresql_username
    group postgresql_group
    mode 0640
  end
end
