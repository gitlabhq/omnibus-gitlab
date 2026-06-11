runit_service "nginx" do
  action :disable
end

consul_service node['nginx']['consul_service_name'] do
  id 'nginx'
  action :delete
  reload_service false unless Services.enabled?('consul')
end
