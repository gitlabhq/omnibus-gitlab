include_recipe 'test_consul::reload_consul'

consul_service 'node-exporter' do
  ip_address '0.0.0.0'
  port 1234
  advertise_addr '1.1.1.1'
end
