runit_service 'nginx' do
  # Dummy, for testing
end

nginx_configuration 'foobar' do
  action :create
end
