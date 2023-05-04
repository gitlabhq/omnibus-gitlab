# When this recipe is used directly, set the attribute, so the crond_job type
# knows we have been enabled.
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('crond')

node.default['crond']['enable'] = true

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

directory node["crond"]["cron_d"] do
  recursive true
  owner "root"
end

runit_service "crond" do
  owner "root"
  group "root"
  options({
    cron_d: node['crond']['cron_d'],
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group]
  }.merge(params))
  log_options logging_settings[:options]
end
