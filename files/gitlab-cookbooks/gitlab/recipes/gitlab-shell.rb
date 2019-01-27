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
account_helper = AccountHelper.new(node)

git_user = account_helper.gitlab_user
git_group = account_helper.gitlab_group
gitlab_shell_dir = "/opt/gitlab/embedded/service/gitlab-shell"
gitlab_shell_var_dir = node['gitlab']['gitlab-shell']['dir']
ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
authorized_keys = node['gitlab']['gitlab-shell']['auth_file']
log_directory = node['gitlab']['gitlab-shell']['log_directory']
gitlab_shell_keys_check = File.join(gitlab_shell_dir, 'bin/gitlab-keys')
gitlab_shell_config_file = File.join(gitlab_shell_var_dir, "config.yml")
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_shell_secret_file = File.join(gitlab_rails_etc_dir, 'gitlab_shell_secret')

# Creates `.ssh` directory to hold authorized_keys
[
  ssh_dir,
  File.dirname(authorized_keys)
].uniq.each do |dir|
  storage_directory dir do
    owner git_user
    group git_group
    mode "0700"
  end
end

[
  log_directory,
  gitlab_shell_var_dir
].each do |dir|
  directory dir do
    owner git_user
    mode "0700"
    recursive true
  end
end

# If no internal_api_url is specified, default to the IP/port Unicorn listens on
api_url = node['gitlab']['gitlab-rails']['internal_api_url']
api_url ||= "http://#{node['gitlab']['unicorn']['listen']}:#{node['gitlab']['unicorn']['port']}#{node['gitlab']['unicorn']['relative_url']}"

templatesymlink "Create a config.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_shell_dir, "config.yml")
  link_to gitlab_shell_config_file
  source "gitlab-shell-config.yml.erb"
  mode "0640"
  owner "root"
  group git_group
  variables({
              user: git_user,
              api_url: api_url,
              authorized_keys: authorized_keys,
              log_file: File.join(log_directory, "gitlab-shell.log"),
              log_level: node['gitlab']['gitlab-shell']['log_level'],
              log_format: node['gitlab']['gitlab-shell']['log_format'],
              audit_usernames: node['gitlab']['gitlab-shell']['audit_usernames'],
              http_settings: node['gitlab']['gitlab-shell']['http_settings'],
              git_trace_log_file: node['gitlab']['gitlab-shell']['git_trace_log_file'],
              custom_hooks_dir: node['gitlab']['gitlab-shell']['custom_hooks_dir']
            })
end

link File.join(gitlab_shell_dir, ".gitlab_shell_secret") do
  to "/opt/gitlab/embedded/service/gitlab-rails/.gitlab_shell_secret"
end

execute "#{gitlab_shell_keys_check} check-permissions" do
  user git_user
  group git_group
end

# If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory and authorized_keys file of the
# git_user is valid.
bash "Set proper security context on ssh files for selinux" do
  code <<~EOS
    semanage fcontext -a -t ssh_home_t '#{ssh_dir}(/.*)?'
    semanage fcontext -a -t ssh_home_t '#{authorized_keys}'
    semanage fcontext -a -t ssh_home_t '#{gitlab_shell_config_file}'
    semanage fcontext -a -t ssh_home_t '#{gitlab_shell_secret_file}'
    restorecon -R -v '#{ssh_dir}'
    restorecon -v '#{authorized_keys}' '#{gitlab_shell_config_file}'
    # On new installs, the gitlab_shell_secret file may not exist until the
    # gitlab-rails recipe runs, so we can safely move along if the file doesn't exist.
    restorecon -v -i '#{gitlab_shell_secret_file}'
  EOS
  only_if "id -Z"
end
