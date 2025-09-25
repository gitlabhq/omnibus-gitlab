resource_name :nginx_configuration
provides :nginx_configuration

unified_mode true

actions :create, :delete
default_action :create

property :name, [String]
property :path, [String, nil]
property :source, [String, nil]
property :cookbook, [String, nil], default: 'gitlab'
property :variables, [Hash], default: {}
property :nginx_helper, default: lazy { OmnibusGitlab::NginxHelper.new(node) }, sensitive: true
property :omnibus_helper, default: lazy { OmnibusHelper.new(node) }, sensitive: true

action :create do
  path = new_resource.path || new_resource.nginx_helper.service_conf_path(new_resource.name)
  template path do
    source new_resource.source || "nginx-gitlab-#{new_resource.name}.conf.erb"
    cookbook new_resource.cookbook
    variables new_resource.variables

    owner "root"
    group "root"
    mode "0644"

    notifies :restart, 'runit_service[nginx]' if new_resource.omnibus_helper.should_notify?('nginx')
    action :create
  end
end

action :delete do
  path = new_resource.path || new_resource.nginx_helper.service_conf_path(new_resource.name)

  file path do
    notifies :restart, 'runit_service[nginx]' if new_resource.omnibus_helper.should_notify?('nginx')
    action :delete
  end
end
