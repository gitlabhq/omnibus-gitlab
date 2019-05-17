node.default['postgresql']['unix_socket_directory'] ||= node['postgresql']['dir']
node.default['postgresql']['data_dir'] ||= "#{node['postgresql']['dir']}/data"
node.default['postgresql']['home'] ||= node['postgresql']['dir']
