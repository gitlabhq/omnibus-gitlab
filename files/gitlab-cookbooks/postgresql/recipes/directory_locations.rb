node.default['gitlab']['postgresql']['unix_socket_directory'] ||= node['gitlab']['postgresql']['dir']
node.default['gitlab']['postgresql']['data_dir'] ||= "#{node['gitlab']['postgresql']['dir']}/data"
node.default['gitlab']['postgresql']['home'] ||= node['gitlab']['postgresql']['dir']
