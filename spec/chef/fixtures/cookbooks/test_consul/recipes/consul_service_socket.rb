include_recipe 'test_consul::reload_consul'

consul_service 'node-exporter' do
  socket_address '0.0.0.0:5678'
  reload_service false
end
