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

if SELinuxDistroHelper.selinux_supported?
  ssh_keygen_module = 'gitlab-7.2.0-ssh-keygen'
  authorized_keys_module = 'gitlab-10.5.0-ssh-authorized-keys'
  gitlab_shell_module = 'gitlab-13.5.0-gitlab-shell'
  gitlab_unified_module = 'gitlab'

  if SELinuxHelper.use_unified_policy?(node)
    execute "semodule -i /opt/gitlab/embedded/selinux/#{gitlab_unified_module}.pp" do
      not_if "getenforce | grep Disabled"
      not_if "semodule -l | grep -E '^#{gitlab_unified_module}([[:space:]]|$)'"
    end

    execute "semodule -r #{ssh_keygen_module}" do
      not_if "getenforce | grep Disabled"
      only_if "semodule -l | grep -E '^#{ssh_keygen_module}([[:space:]]|$)'"
    end

    execute "semodule -r #{authorized_keys_module}" do
      not_if "getenforce | grep Disabled"
      only_if "semodule -l | grep -E '^#{authorized_keys_module}([[:space:]]|$)'"
    end

    execute "semodule -r #{gitlab_shell_module}" do
      not_if "getenforce | grep Disabled"
      only_if "semodule -l | grep -E '^#{gitlab_shell_module}([[:space:]]|$)'"
    end
  else
    execute "semodule -i /opt/gitlab/embedded/selinux/#{ssh_keygen_module}.pp" do
      not_if "getenforce | grep Disabled"
      not_if "semodule -l | grep -E '^#{ssh_keygen_module}([[:space:]]|$)'"
    end

    execute "semodule -i /opt/gitlab/embedded/selinux/#{authorized_keys_module}.pp" do
      not_if "getenforce | grep Disabled"
      not_if "semodule -l | grep -E '^#{authorized_keys_module}([[:space:]]|$)'"
    end

    execute "semodule -i /opt/gitlab/embedded/selinux/#{gitlab_shell_module}.pp" do
      not_if "getenforce | grep Disabled"
      not_if "semodule -l | grep -E '^#{gitlab_shell_module}([[:space:]]|$)'"
    end

    execute "semodule -r #{gitlab_unified_module}" do
      not_if "getenforce | grep Disabled"
      only_if "semodule -l | grep -E '^#{gitlab_unified_module}([[:space:]]|$)'"
    end
  end
end

# If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory and authorized_keys file of the
# git_user is valid.
bash "Set proper security context on ssh files for selinux" do
  code lazy { SELinuxHelper.commands(node) }
  only_if "id -Z"
  not_if { !node['gitlab']['gitlab_rails']['enable'] }
  action :nothing
end
