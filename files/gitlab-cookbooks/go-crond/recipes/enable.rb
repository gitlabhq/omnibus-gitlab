# When this recipe is used directly, set the attribute, so the go_crond_job type
# knows we have been enabled.
node.default['go-crond']['enable'] = true

directory node['go-crond']['log_directory'] do
  owner "root"
end

directory node["go-crond"]["cron_d"] do
  recursive true
  owner "root"
end

runit_service "go-crond" do
  owner "root"
  group "root"
  options node['go-crond']
  log_options log_options node['gitlab']['logging'].to_hash.merge(node["go-crond"].to_hash)
end
