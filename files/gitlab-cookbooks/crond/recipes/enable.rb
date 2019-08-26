# When this recipe is used directly, set the attribute, so the crond_job type
# knows we have been enabled.
node.default['crond']['enable'] = true

directory node['crond']['log_directory'] do
  owner "root"
  mode "0750"
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
    log_directory: node['crond']['log_directory']
  }.merge(params))
  log_options log_options node['gitlab']['logging'].to_hash.merge(node["crond"].to_hash)
end
