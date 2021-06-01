node.default['postgresql']['unix_socket_directory'] ||= node['postgresql']['dir']
node.default['postgresql']['home'] ||= node['postgresql']['dir']
