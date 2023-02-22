default['gitaly']['enable'] = false
default['gitaly']['ha'] = false
default['gitaly']['dir'] = "/var/opt/gitlab/gitaly"
default['gitaly']['env_directory'] = "/opt/gitlab/etc/gitaly/env"
# default['gitaly']['env'] is set in ../recipes/enable.rb
default['gitaly']['bin_path'] = "/opt/gitlab/embedded/bin/gitaly"
default['gitaly']['storage'] = []
default['gitaly']['open_files_ulimit'] = 15000
default['gitaly']['consul_service_name'] = 'gitaly'
default['gitaly']['consul_service_meta'] = nil

default['gitaly']['configuration'] = {
  runtime_dir: "#{node['gitaly']['dir']}/run",
  socket_path: "#{node['gitaly']['dir']}/gitaly.socket",
  prometheus_listen_addr: 'localhost:9236',
  logging: {
    dir: '/var/log/gitlab/gitaly',
    format: 'json'
  },
  git: {
    use_bundled_binaries: true,
    bin_path: "#{node['package']['install-dir']}/embedded/bin/git"
  }
}
