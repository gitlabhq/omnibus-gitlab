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
include_recipe 'postgresql::directory_locations'

pg_helper = PgHelper.new(node)
geo_pg_helper = GeoPgHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
postgresql_install_dir = File.join(node['package']['install-dir'], 'embedded/postgresql')

if Services.enabled?('postgresql')
  running_db_version = pg_helper.database_version
elsif Services.enabled?('geo_postgresql')
  running_db_version = geo_pg_helper.database_version
end

db_version = node['postgresql']['version'] || running_db_version
db_path = Dir.glob("#{postgresql_install_dir}/#{db_version}*").min if db_version

ruby_block 'check_postgresql_version' do
  block do
    LoggingHelper.warning("We do not ship client binaries for PostgreSQL #{db_version}, defaulting to #{pg_helper.version.major}")
  end

  not_if { node['postgresql']['version'].nil? || db_path }
end

ruby_block 'check_postgresql_version_is_deprecated' do
  block do
    LoggingHelper.warning(%q(
      Note that PostgreSQL 12 is the minimum required PostgreSQL version in GitLab 14.0.
      To upgrade, please see: https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server
    ))
  end

  not_if { node['postgresql']['version'].nil? || node['postgresql']['version'].to_f >= 12 }
end

ruby_block "Link postgresql bin files to the correct version" do
  block do
    # Fallback to the psql version if needed
    pg_path = db_path || Dir.glob("#{postgresql_install_dir}/#{pg_helper.version.major}*").min

    raise "Could not find PostgreSQL binaries" unless pg_path

    Dir.glob("#{pg_path}/bin/*").each do |pg_bin|
      FileUtils.ln_sf(pg_bin, "#{node['package']['install-dir']}/embedded/bin/#{File.basename(pg_bin)}")
    end
  end

  only_if do
    !File.exist?(File.join(node['postgresql']['dir'], 'data', "PG_VERSION")) || \
      pg_helper.version.major !~ /^#{pg_helper.database_version}/ || \
      (Services.enabled?('geo_postgresql') && geo_pg_helper.version.major !~ /^#{geo_pg_helper.database_version}/) || \
      !node['postgresql']['version'].nil?
  end

  # This recipe will also be called standalone so the resource won't exist in some circumstances
  # This is why we check whether it is defined in runtime or not
  notifies :restart, 'runit_service[postgresql]', :immediately if omnibus_helper.should_notify?("postgresql") && omnibus_helper.resource_available?('runit_service[postgresql]')
end

# This template is needed to make the gitlab-psql script and PgHelper work
template "/opt/gitlab/etc/gitlab-psql-rc" do
  owner 'root'
  group 'root'
  sensitive true
end
