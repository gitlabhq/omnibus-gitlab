resource_name :puma_config
provides :puma_config

unified_mode true

property :filename, String, name_property: true
property :tag, String, default: 'gitlab-puma-worker'
property :rackup, String, default: 'config.ru'
property :environment, String, default: 'production'
property :install_dir, [String, nil], default: lazy { node['package']['install-dir'] }
property :listen_socket, [String, nil], default: nil
property :listen_tcp, [String, nil], default: nil
property :ssl_listen_host, [String, nil], default: nil
property :ssl_port, [Integer, nil], default: nil
property :ssl_certificate, [String, nil], default: nil
property :ssl_certificate_key, [String, nil], default: nil
property :ssl_client_certificate, [String, nil], default: nil
property :ssl_cipher_filter, [String, nil], default: nil
property :ssl_verify_mode, String, default: 'none'
property :working_directory, [String, nil], default: nil
property :worker_timeout, Integer, default: 60
property :per_worker_max_memory_mb, [Integer, nil], default: nil
property :worker_processes, Integer, default: 2
property :min_threads, Integer, default: 4
property :max_threads, Integer, default: 4
property :pid, [String, nil], default: nil
property :state_path, [String, nil], default: nil
property :stderr_path, [String, nil], default: nil
property :stdout_path, [String, nil], default: nil
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :mode, String, default: '0644'
property :dependent_services, Array, default: []
property :cookbook, String

action :create do
  config_dir = ::File.dirname(new_resource.filename)

  directory config_dir do
    recursive true
    action :create
  end

  template new_resource.filename do
    source "puma.rb.erb"
    mode "0644"
    cookbook new_resource.cookbook if new_resource.cookbook
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    mode new_resource.mode   if new_resource.mode
    variables new_resource.to_hash
    new_resource.dependent_services.each { |svc| notifies :restart, svc }
  end
end
