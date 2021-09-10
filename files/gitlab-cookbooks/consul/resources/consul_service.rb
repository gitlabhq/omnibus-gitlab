resource_name :consul_service
provides :consul_service

property :service_name, String, name_property: true
property :id, String, name_property: true
property :ip_address, [String, nil], default: nil
property :meta, [Hash, nil], default: nil
property :port, [Integer, nil], default: nil
property :reload_service, [TrueClass, FalseClass], default: true

# Combined address plus port - 0.0.0.0:1234
property :socket_address, [String, nil], default: nil

action :create do
  if property_is_set?(:socket_address)
    ip_address, port = new_resource.socket_address.split(':')
    ip_address = translate_address(ip_address)
  elsif property_is_set?(:ip_address) && property_is_set?(:port)
    ip_address = translate_address(new_resource.ip_address)
    port = new_resource.port
  else
    raise "Missing required properties: `socket_address` or both `ip_address` and `port`."
  end

  service_name = sanitize_service_name(new_resource.service_name)
  file_name = sanitize_service_name(new_resource.id)

  content = {
    'service' => {
      'name' => service_name,
      'address' => ip_address,
      'port' => port.to_i
    }
  }

  # Remove address if advertise_addr is set to allow service to use underlying advertise_addr
  content['service'].delete('address') if node['consul']['configuration']['advertise_addr']

  content['service']['meta'] = new_resource.meta if property_is_set?(:meta)

  # Ensure the dir exists but leave permissions to `consul::enable`
  directory node['consul']['config_dir'] do
    recursive true
  end

  file "#{node['consul']['config_dir']}/#{file_name}-service.json" do
    content content.to_json
    notifies :run, 'execute[reload consul]' if new_resource.reload_service
  end
end

action :delete do
  file_name = sanitize_service_name(new_resource.id)

  file "#{node['consul']['config_dir']}/#{file_name}-service.json" do
    action :delete
    notifies :run, 'execute[reload consul]' if new_resource.reload_service
  end
end

# Consul allows dashes but not underscores for DNS service discovery.
# Avoid logging errors by changing all underscores to dashes.
def sanitize_service_name(name)
  name.tr('_', '-')
end

# A listen address of 0.0.0.0 binds to all interfaces.
# Translate that listen address to the node's actual
# IP address so external services know where to connect.
def translate_address(address)
  return node['ipaddress'] if ['0.0.0.0', '*'].include?(address)

  address
end
