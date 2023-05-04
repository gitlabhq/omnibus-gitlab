account_helper = AccountHelper.new(node)
pg_helper = PgHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('postgresql')
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

runit_service "postgresql" do
  start_down node['postgresql']['ha']
  supervisor_owner postgresql_username
  supervisor_group postgresql_group
  restart_on_update false
  control(['t'])
  options({
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
  }.merge(params))
  log_options logging_settings[:options]
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start postgresql" do
    retries 20
  end
end

###
# Create the users the database, enable required extensions, and grant users the required privileges
###
database_objects 'postgresql' do
  pg_helper pg_helper
  account_helper account_helper
  not_if { pg_helper.replica? }
end

version_file 'Create version file for PostgreSQL' do
  version_file_path File.join(node['postgresql']['dir'], 'VERSION')
  version_check_cmd "/opt/gitlab/embedded/bin/postgres --version"
  notifies :restart, 'runit_service[postgresql]', :immediately if node['postgresql']['auto_restart_on_version_change'] && pg_helper.is_running? && omnibus_helper.should_notify?("postgresql") && pg_helper.bootstrapped?
end

ruby_block 'warn pending postgresql restart' do
  block do
    message = <<~MESSAGE
      The version of the running postgresql service is different than what is installed.
      Please restart postgresql to start the new version.

      sudo gitlab-ctl restart postgresql
    MESSAGE
    LoggingHelper.warning(message)
  end
  only_if { pg_helper.is_running? && pg_helper.running_version != pg_helper.version }
  not_if { node['postgresql']['auto_restart_on_version_change'] }
end

execute 'reload postgresql' do
  command %(/opt/gitlab/bin/gitlab-ctl hup postgresql)
  retries 20
  action :nothing
  only_if { pg_helper.is_running? }
end

execute 'start postgresql' do
  command %(/opt/gitlab/bin/gitlab-ctl start postgresql)
  retries 20
  action :nothing
  not_if { pg_helper.is_running? }
end
