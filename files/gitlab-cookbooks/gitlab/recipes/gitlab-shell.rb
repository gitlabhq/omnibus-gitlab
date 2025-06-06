#
## Copyright:: Copyright (c) 2014 GitLab Inc.
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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitlab-shell')
logging_settings_sshd = logfiles_helper.logging_settings('gitlab-sshd')

omnibus_helper = OmnibusHelper.new(node)
sshd_helper = GitlabSshdHelper.new(node)

git_user = account_helper.gitlab_user
git_group = account_helper.gitlab_group
gitlab_shell_dir = "/opt/gitlab/embedded/service/gitlab-shell"
gitlab_shell_var_dir = node['gitlab']['gitlab_shell']['dir']
ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
authorized_keys = node['gitlab']['gitlab_shell']['auth_file']
gitlab_shell_config_file = File.join(gitlab_shell_var_dir, "config.yml")

gitlab_sshd_enabled = Services.enabled?('gitlab_sshd')
gitlab_sshd_generate_host_keys = node['gitlab']['gitlab_sshd']['generate_host_keys']
gitlab_sshd_bin_path = File.join(gitlab_shell_dir, 'bin', 'gitlab-sshd')
gitlab_sshd_working_dir = node['gitlab']['gitlab_sshd']['dir']
gitlab_sshd_env_dir = node['gitlab']['gitlab_sshd']['env_directory']
gitlab_sshd_host_key_dir = node['gitlab']['gitlab_sshd']['host_keys_dir']

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

directories = [
  gitlab_shell_var_dir,
]

directories += [gitlab_sshd_working_dir] if gitlab_sshd_enabled

directories.each do |dir|
  directory dir do
    owner git_user
    mode "0700"
    recursive true
  end
end

# Create log_director(ies)
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

if gitlab_sshd_enabled
  directory logging_settings_sshd[:log_directory] do
    owner logging_settings_sshd[:log_directory_owner]
    mode logging_settings_sshd[:log_directory_mode]
    if log_group = logging_settings_sshd[:log_directory_group]
      group log_group
    end
    recursive true
  end
end

gitlab_url, gitlab_relative_path = WebServerHelper.internal_api_url(node)
ssh_key_path = File.join(gitlab_sshd_host_key_dir, '/etc/ssh')

bash 'generate gitlab-sshd host keys' do
  action
  only_if { gitlab_sshd_enabled && gitlab_sshd_generate_host_keys && Dir.exist?(gitlab_sshd_host_key_dir) && sshd_helper.no_host_keys? }
  code <<~EOS
    set -e
    mkdir -p #{ssh_key_path}
    success=0
    for crypto in rsa ecdsa ed25519
    do
        filename="#{gitlab_sshd_host_key_dir}/ssh_host_${crypto}_key"
        echo "Generating ${filename}..."
        # Some keys may not be supported on FIPS-enabled systems, so skip over them.
        ssh-keygen -q -N "" -t ${crypto} -f "${filename}" < /dev/null || true

        if [[ -f "${filename}" ]]; then
          success=1
          chmod 0600 "${filename}"
          chown #{git_user}:#{git_group} "${filename}"
        else
          echo "${filename} was not generated"
        fi
    done

    if [[ ${success} -ne 1 ]]; then
        echo "Failed to generate any keys, aborting."
        exit 1
    fi
  EOS
end

gitlab_rails_dir = node['gitlab']['gitlab_rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_shell_secret_file = File.join(gitlab_rails_etc_dir, 'gitlab_shell_secret')

templatesymlink "Create a config.yml and create a symlink to Rails root" do
  link_from File.join(gitlab_shell_dir, "config.yml")
  link_to gitlab_shell_config_file
  source "gitlab-shell-config.yml.erb"
  mode "0640"
  owner "root"
  group git_group
  variables(
    lazy do
      {
        user: git_user,
        gitlab_url: gitlab_url,
        gitlab_relative_path: gitlab_relative_path,
        authorized_keys: authorized_keys,
        secret_file: gitlab_shell_secret_file,
        log_file: File.join(logging_settings[:log_directory], "gitlab-shell.log"),
        log_level: node['gitlab']['gitlab_shell']['log_level'],
        log_format: node['gitlab']['gitlab_shell']['log_format'],
        audit_usernames: node['gitlab']['gitlab_shell']['audit_usernames'],
        http_settings: node['gitlab']['gitlab_shell']['http_settings'],
        git_trace_log_file: node['gitlab']['gitlab_shell']['git_trace_log_file'],
        ssl_cert_dir: node['gitlab']['gitlab_shell']['ssl_cert_dir'],
        gitlab_sshd: gitlab_sshd_enabled ? sshd_helper.json_config : nil,
        lfs_pure_ssh_protocol: node['gitlab']['gitlab_shell']['lfs_pure_ssh_protocol'],
        pat: node['gitlab']['gitlab_shell']['pat']
      }
    end
  )
  notifies :run, 'bash[Set proper security context on ssh files for selinux]', :delayed if SELinuxHelper.enabled?
  notifies :restart, "runit_service[gitlab-sshd]" if gitlab_sshd_enabled
  sensitive true
end

link File.join(gitlab_shell_dir, ".gitlab_shell_secret") do
  to "/opt/gitlab/embedded/service/gitlab-rails/.gitlab_shell_secret"
end

file authorized_keys do
  owner git_user
  group git_group
  mode '600'
  action :create_if_missing
  notifies :run, 'bash[Set proper security context on ssh files for selinux]', :delayed if SELinuxHelper.enabled?
end

env_dir gitlab_sshd_env_dir do
  action gitlab_sshd_enabled ? :create : :nothing
  variables node['gitlab']['gitlab_sshd']['env']
  notifies :restart, "runit_service[gitlab-sshd]" if omnibus_helper.should_notify?('gitlab_sshd')
end

runit_service 'gitlab-sshd' do
  action gitlab_sshd_enabled ? :enable : :disable
  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    working_dir: gitlab_sshd_working_dir,
    env_dir: gitlab_sshd_env_dir,
    bin_path: gitlab_sshd_bin_path,
    config_dir: gitlab_shell_var_dir,
    log_directory: logging_settings_sshd[:log_directory],
    log_user: logging_settings_sshd[:runit_owner],
    log_group: logging_settings_sshd[:runit_group],
  }.merge(params))
end
