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
pg_helper = PgHelper.new(node)
geo_pg_helper = GeoPgHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
postgresql_install_dir = File.join(node['package']['install-dir'], 'embedded/postgresql')

include_recipe 'postgresql::directory_locations'

# This recipe will also be called standalone so the resource
# won't exist for resource collection.
# We only have ourselves to blame here, we want DRY code this is what we get.
# The block below is cleanest solution and
# was found at https://gist.github.com/scalp42/7606857#gistcomment-1618630
resource_exists = proc do |name|
  begin
    resources name
    true
  rescue Chef::Exceptions::ResourceNotFound
    false
  end
end

main_db_version = pg_helper.database_version if Services.enabled?('postgresql')
geo_db_version = geo_pg_helper.database_version if Services.enabled?('geo_postgresql')
db_version = node['postgresql']['version'] || main_db_version || geo_db_version
db_path = db_version && Dir.glob("#{postgresql_install_dir}/#{db_version}*").min

ruby_block 'check_postgresql_version' do
  block do
    LoggingHelper.warning("We do not ship client binaries for PostgreSQL #{db_version}, defaulting to #{pg_helper.version.major}")
  end
  not_if { node['postgresql']['version'].nil? || db_path }
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
    !File.exist?(File.join(node['postgresql']['data_dir'], "PG_VERSION")) || \
      pg_helper.version.major !~ /^#{pg_helper.database_version}/ || \
      (Services.enabled?('geo_postgresql') && geo_pg_helper.version.major !~ /^#{geo_pg_helper.database_version}/) || \
      !node['postgresql']['version'].nil?
  end
  notifies :restart, 'runit_service[postgresql]', :immediately if omnibus_helper.should_notify?("postgresql") && resource_exists['runit_service[postgresql]']
end
