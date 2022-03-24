include_recipe 'test_consul::reload_consul'

meta = { some_key: "value" }

consul_service 'node-exporter' do
  ip_address '0.0.0.0'
  port 1234
  meta meta
end
