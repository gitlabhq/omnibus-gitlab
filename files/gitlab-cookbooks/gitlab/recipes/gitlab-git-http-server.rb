working_dir = node['gitlab']['gitlab-git-http-server']['dir']
log_dir = node['gitlab']['gitlab-git-http-server']['log_dir']

directory working_dir do
  owner node['gitlab']['user']['username']
  group node['gitlab']['web-server']['username']
  mode '0750'
  recursive true
end
  
directory log_dir do
  owner node['gitlab']['user']['username']
  mode '0700'
  recursive true
end

runit_service 'gitlab-git-http-server' do
  down node['gitlab']['gitlab-git-http-server']['ha']
  options({
    :log_directory => log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-git-http-server'].to_hash)
end
