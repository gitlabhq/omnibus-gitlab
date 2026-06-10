node['oak']['components'].each do |name, config|
  nginx_configuration name do
    action :delete
  end
end
