resource_name :unicorn_service

property :rails_app
property :svc, String, name_property: true
property :user, String
property :group, String

action :create do
  rails_home = node['gitlab'][new_resource.rails_app]['dir']
  omnibus_helper = OmnibusHelper.new(node)
  metrics_dir = ::File.join(node['gitlab']['runtime-dir'].to_s, 'gitlab/unicorn') unless node['gitlab']['runtime-dir'].nil?

  unicorn_etc_dir = ::File.join(rails_home, "etc")
  unicorn_working_dir = ::File.join(rails_home, "working")

  unicorn_listen_socket = node['gitlab'][new_resource.svc]['socket']
  unicorn_pidfile = node['gitlab'][new_resource.svc]['pidfile']
  unicorn_log_dir = node['gitlab'][new_resource.svc]['log_directory']
  unicorn_socket_dir = ::File.dirname(unicorn_listen_socket)

  [
    unicorn_log_dir,
    ::File.dirname(unicorn_pidfile)
  ].each do |dir_name|
    directory dir_name do
      owner new_resource.user
      mode '0700'
      recursive true
    end
  end

  directory unicorn_socket_dir do
    owner new_resource.user
    group AccountHelper.new(node).web_server_group
    mode '0750'
    recursive true
  end

  unicorn_listen_tcp = [node['gitlab'][new_resource.svc]['listen'], node['gitlab'][new_resource.svc]['port']].join(':')

  unicorn_rb = ::File.join(unicorn_etc_dir, "unicorn.rb")
  unicorn_config unicorn_rb do
    listen(
      unicorn_listen_tcp => {
        tcp_nopush: node['gitlab'][new_resource.svc]['tcp_nopush']
      },
      unicorn_listen_socket => {
        backlog: node['gitlab'][new_resource.svc]['backlog_socket'],
      }
    )
    worker_timeout node['gitlab'][new_resource.svc]['worker_timeout']
    worker_memory_limit_min node['gitlab'][new_resource.svc]['worker_memory_limit_min']
    worker_memory_limit_max node['gitlab'][new_resource.svc]['worker_memory_limit_max']
    working_directory unicorn_working_dir
    worker_processes node['gitlab'][new_resource.svc]['worker_processes']
    preload_app true
    stderr_path ::File.join(unicorn_log_dir, "unicorn_stderr.log")
    stdout_path ::File.join(unicorn_log_dir, "unicorn_stdout.log")
    relative_url node['gitlab'][new_resource.svc]['relative_url']
    pid unicorn_pidfile
    install_dir node['package']['install-dir']
    owner "root"
    group "root"
    mode "0644"
    notifies_services :restart, "runit_service[#{new_resource.svc}]" if omnibus_helper.should_notify?(new_resource.svc)
  end

  runit_service new_resource.svc do
    start_down node['gitlab'][new_resource.svc]['ha']
    # unicorn-worker-wrapper receives a HUP and issues a SIGUSR2 and QUIT
    # to the master unicorn process
    restart_command_name 'hup'
    template_name 'unicorn'
    control ['t']
    options({
      service: new_resource.svc,
      user: new_resource.user,
      groupname: new_resource.group,
      rails_app: new_resource.rails_app,
      unicorn_rb: unicorn_rb,
      log_directory: unicorn_log_dir,
      metrics_dir: metrics_dir,
      clean_metrics_dir: false
    }.merge(new_resource))
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][new_resource.svc].to_hash)

    notifies :stop, 'runit_service[puma]', :before
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{new_resource.svc}" do
      retries 20
    end
  end
end

action :restart do
  runit_service new_resource.svc do
    action :restart
  end
end

action :stop do
  runit_service new_resource.svc do
    action :stop
  end
end

action :disable do
  runit_service new_resource.svc do
    action :disable
  end
end
