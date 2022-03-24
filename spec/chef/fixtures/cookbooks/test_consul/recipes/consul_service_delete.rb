include_recipe 'test_consul::reload_consul'

consul_service 'delete_me' do
  action :delete
end
