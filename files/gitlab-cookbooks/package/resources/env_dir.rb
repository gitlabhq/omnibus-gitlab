resource_name :env_dir
provides :env_dir

actions :create, :delete
default_action :create

property :variables, Hash, default: {}
property :restarts, Array, default: []

action :create do
  directory name do
    recursive true
  end

  variables.each do |key, value|
    file ::File.join(name, key) do
      content value
      restarts.each do |svc|
        notifies :restart, svc
      end
    end
  end
end

action :delete do
  if ::File.directory?(name)
    deleted_env_vars = Dir.entries(name) - variables.keys - %w(. ..)
    deleted_env_vars.each do |deleted_var|
      file ::File.join(name, deleted_var) do
        action :delete
        restarts.each do |svc|
          notifies :restart, svc
        end
      end
    end
  end
end
