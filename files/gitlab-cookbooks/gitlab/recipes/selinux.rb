#
# Copyright:: Copyright (c) 2014 GitLab B.V.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if RedhatHelper.system_is_rhel7?
  ssh_keygen_module = 'gitlab-7.2.0-ssh-keygen'
  execute "semodule -i /opt/gitlab/embedded/selinux/rhel/7/#{ssh_keygen_module}.pp" do
    not_if "getenforce | grep Disabled"
    not_if "semodule -l | grep '^#{ssh_keygen_module}\\s'"
  end

  authorized_keys_module = 'gitlab-10.5.0-ssh-authorized-keys'
  execute "semodule -i /opt/gitlab/embedded/selinux/rhel/7/#{authorized_keys_module}.pp" do
    not_if "getenforce | grep Disabled"
    not_if "semodule -l | grep '^#{authorized_keys_module}\\s'"
  end
end

ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
authorized_keys = node['gitlab']['gitlab-shell']['auth_file']
gitlab_shell_var_dir = node['gitlab']['gitlab-shell']['dir']
gitlab_shell_config_file = File.join(gitlab_shell_var_dir, "config.yml")
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_shell_secret_file = File.join(gitlab_rails_etc_dir, 'gitlab_shell_secret')

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
    restorecon -v '#{gitlab_shell_secret_file}'
  EOS
  only_if "id -Z"
end
