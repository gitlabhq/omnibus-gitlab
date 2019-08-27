include_recipe 'test_consul::reload_consul'

consul_service 'delete_no_reload' do
  action :delete
  reload_service false
end
