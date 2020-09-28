resource_name :unicorn_config

property :listen, Hash
property :working_directory
property :worker_timeout, Integer, default: 60
property :worker_memory_limit_min
property :worker_memory_limit_max
property :preload_app, [true, false], default: false
property :worker_processes, Integer, default: 4
property :pid
property :stderr_path
property :stdout_path
property :relative_url
property :owner
property :group
property :mode
property :install_dir

action :create do
  config_dir = ::File.dirname(new_resource.name)

  directory config_dir do
    recursive true
    action :create
  end

  new_resource.listen.each do |port, options|
    oarray = []
    options.each do |k, v|
      oarray << ":#{k} => #{v}"
    end
    new_resource.listen[port] = oarray.join(", ")
  end

  template new_resource.name do
    source "unicorn.rb.erb"
    mode "0644"
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    mode new_resource.mode if new_resource.mode
    variables new_resource.to_hash
  end
end
