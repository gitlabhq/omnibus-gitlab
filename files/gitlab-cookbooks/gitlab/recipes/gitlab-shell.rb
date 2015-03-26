#
## Copyright:: Copyright (c) 2014 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

git_user = node['gitlab']['user']['username']
git_group = node['gitlab']['user']['group']
gitlab_shell_dir = "/opt/gitlab/embedded/service/gitlab-shell"
gitlab_shell_var_dir = "/var/opt/gitlab/gitlab-shell"
repositories_path = node['gitlab']['gitlab-rails']['gitlab_shell_repos_path']
ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
authorized_keys = File.join(ssh_dir, "authorized_keys")
log_directory = node['gitlab']['gitlab-shell']['log_directory']

# Create directories because the git_user does not own its home directory
directory repositories_path do
  owner git_user
  group git_group
  mode "2770"
  recursive true
end

directory ssh_dir do
  owner git_user
  group git_group
  mode "0700"
  recursive true
end

file authorized_keys do
  owner git_user
  group git_group
  mode "0600"
end

# gitlab-shell 1.9.4 uses a lock file in the gitlab-shell root
file File.join(gitlab_shell_dir, "authorized_keys.lock") do
  owner git_user
  group git_group
end

# If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory of the
# git_user is valid.
execute "chcon --recursive --type ssh_home_t #{ssh_dir}" do
  only_if "id -Z"
end

[
  log_directory,
  gitlab_shell_var_dir,
  node['gitlab']['gitlab-shell']['git_data_directory']
].each do |dir|
  directory dir do
    owner git_user
    mode "0700"
    recursive true
  end
end

# If no internal_api_url is specified, default to the IP/port Unicorn listens on
api_url = node['gitlab']['gitlab-rails']['internal_api_url']
api_url ||= "http://#{node['gitlab']['unicorn']['listen']}:#{node['gitlab']['unicorn']['port']}"

redis_port = node['gitlab']['gitlab-rails']['redis_port']
if redis_port
  # Leave out redis socket setting because in gitlab-shell, setting a Redis socket
  # overrides TCP connection settings.
  redis_socket = nil
else
  redis_socket = node['gitlab']['gitlab-rails']['redis_socket']
end

template_symlink File.join(gitlab_shell_var_dir, "config.yml") do
  link_from File.join(gitlab_shell_dir, "config.yml")
  source "gitlab-shell-config.yml.erb"
  variables(
    :user => git_user,
    :api_url => api_url,
    :repositories_path => repositories_path,
    :authorized_keys => authorized_keys,
    :redis_host => node['gitlab']['gitlab-rails']['redis_host'],
    :redis_port => redis_port,
    :redis_socket => redis_socket,
    :redis_database => node['gitlab']['gitlab-rails']['redis_database'],
    :log_file => File.join(log_directory, "gitlab-shell.log"),
    :log_level => node['gitlab']['gitlab-shell']['log_level'],
    :audit_usernames => node['gitlab']['gitlab-shell']['audit_usernames'],
    :http_settings => node['gitlab']['gitlab-shell']['http_settings'],
    :git_annex_enabled => node['gitlab']['gitlab-shell']['git_annex_enabled']
  )
end

template_symlink File.join(gitlab_shell_var_dir, "gitlab_shell_secret") do
  link_from File.join(gitlab_shell_dir, ".gitlab_shell_secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-shell'].to_hash)
end
