puma_config '/var/opt/gitlab/gitlab-rails/etc/puma.rb' do
  environment 'production'
  pid '/opt/gitlab/var/puma/puma.pid'
  state_path '/opt/gitlab/var/puma/puma.state'
  listen_socket '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
  listen_tcp '127.0.0.1:8080'
  working_directory '/var/opt/gitlab/gitlab-rails/working'
  worker_processes 2
  per_worker_max_memory_mb 1000
  install_dir '/opt/gitlab'
  cookbook 'gitlab'

  action :create
end
