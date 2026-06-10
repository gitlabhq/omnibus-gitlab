account_helper = AccountHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('nginx')

nginx_helper = OmnibusGitlab::NginxHelper.new(node)

nginx_dir = nginx_helper.nginx_dir
nginx_conf_dir = nginx_helper.conf_dir
nginx_service_conf_dir = nginx_helper.service_conf_dir
nginx_upstream_definition_dir = nginx_helper.upstream_definition_dir
nginx_extra_metrics_dir = nginx_helper.extra_metrics_dir

# These directories do not need to be writable for gitlab-www
[
  nginx_dir,
  nginx_conf_dir,
  nginx_service_conf_dir,
  nginx_upstream_definition_dir,
  nginx_extra_metrics_dir
].each do |dir_name|
  directory dir_name do
    owner 'root'
    group account_helper.web_server_group
    mode '0750'
    recursive true
  end
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

link File.join(nginx_dir, "logs") do
  to logging_settings[:log_directory]
end

# Cleanup old config files
# TODO: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9316
%w[
  http
  smartcard-http
  mattermost-http
  pages
  registry
  kas
].each do |component|
  old_conf_file = File.join(nginx_conf_dir, "gitlab-#{component}.conf")

  template old_conf_file do
    action :delete
  end
end
