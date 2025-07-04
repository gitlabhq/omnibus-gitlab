#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('gitaly')

working_dir = node['gitaly']['dir']
env_directory = node['gitaly']['env_directory']
config_path = File.join(working_dir, "config.toml")
gitaly_path = node['gitaly']['bin_path']
wrapper_path = "#{gitaly_path}-wrapper"
pid_file = File.join(working_dir, "gitaly.pid")
json_logging = node.dig('gitaly', 'configuration', 'logging', 'format').eql?('json')
open_files_ulimit = node['gitaly']['open_files_ulimit']
runtime_dir = node.dig('gitaly', 'configuration', 'runtime_dir')
cgroups_enabled = node.dig('gitaly', 'configuration', 'cgroups', 'repositories', 'count')&.positive?
cgroups_mountpoint = node.dig('gitaly', 'configuration', 'cgroups', 'mountpoint') || '/sys/fs/cgroup'
cgroups_hierarchy_root = node.dig('gitaly', 'configuration', 'cgroups', 'hierarchy_root') || File.join('gitlab.slice', 'gitaly')
cgroups_parent_cgroup_procs_file = File.join(cgroups_mountpoint, File.dirname(cgroups_hierarchy_root), 'cgroup.procs')
use_wrapper = node['gitaly']['use_wrapper']

include_recipe 'gitaly::git_data_dirs'

directory working_dir do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

directory runtime_dir do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

# Support for the internal socket directory was removed in v15.0. If the old
# default internal socket directory still exists we can thus remove it.
directory File.join(node['gitaly']['dir'], 'internal_sockets') do
  action :delete
  recursive true
end

# Doing this in attributes/default.rb will need gitlab cookbook to be loaded
# before gitaly cookbook. This means gitaly cookbook has to depend on gitlab
# cookbook.  Since gitlab cookbook already depends on gitaly cookbook, this
# causes a circular dependency. To avoid it, the default value is set in the
# recipe itself.
node.default['gitaly']['env'] = {
  'HOME' => node['gitlab']['user']['home'],
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin",
  'TZ' => ':/etc/localtime',
  # This is needed by gitlab-markup to import Python docutils
  'PYTHONPATH' => "#{node['package']['install-dir']}/embedded/lib/python3.9/site-packages",
  # Charlock Holmes and libicu will report U_FILE_ACCESS_ERROR if this is not set to the right path
  # See https://gitlab.com/gitlab-org/gitlab-foss/issues/17415#note_13868167
  'ICU_DATA' => "#{node['package']['install-dir']}/embedded/share/icu/current",
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
  # wrapper script parameters
  'GITALY_PID_FILE' => pid_file,
  'WRAPPER_JSON_LOGGING' => json_logging.to_s,
  'GODEBUG' => "tlsmlkem=0",
}

env_dir env_directory do
  variables node['gitaly']['env']
  notifies :restart, "runit_service[gitaly]" if omnibus_helper.should_notify?('gitaly')
end

gitlab_url, gitlab_relative_path = WebServerHelper.internal_api_url(node)

secret_file = node['gitaly']['configuration']['gitlab']['secret_file']
file secret_file do
  owner "root"
  group "root"
  mode "0644"
  sensitive true
  content node['gitaly']['gitlab_secret']
  notifies :restart, 'runit_service[gitaly]' if omnibus_helper.should_notify?('gitaly')
end

template "Create Gitaly config.toml" do
  path config_path
  source "gitaly-config.toml.erb"
  owner "root"
  group account_helper.gitlab_group
  mode "0640"
  variables node['gitaly'].to_hash.merge(
    {
      configuration: node.dig('gitaly', 'configuration').merge(
        {
          # The gitlab section is not configured by the user directly. Its values are derived
          # from other configuration.
          gitlab: {
            url: gitlab_url,
            relative_url_root: gitlab_relative_path,
            'http-settings': node.dig('gitlab', 'gitlab_shell', 'http_settings')
          }.merge(node.dig('gitaly', 'configuration', 'gitlab') || {}).compact,

          # These options below were historically hard coded values in the template. They
          # are set here to retain the behavior of them not being overridable by the user.
          bin_dir: '/opt/gitlab/embedded/bin',
          git: (node.dig('gitaly', 'configuration', 'git') || {}).merge(
            {
              # Ignore gitconfig files so that the only source of truth for how Git commands
              # are configured are Gitaly's own defaults and the Git configuration injected
              # in this file.
              ignore_gitconfig: true
            }
          ),
          # Omnibus provides defaults for the mountpoint and hierarchy_root if not explicitly
          # set by the user. This provides a working out-of-box configuration since we override
          # runsv's cgroup subtree location in gitlab-runsvdir.service.erb.
          cgroups: cgroups_enabled && (node.dig('gitaly', 'configuration', 'cgroups') || {}).merge(
            {
              mountpoint: cgroups_mountpoint,
              hierarchy_root: cgroups_hierarchy_root,
            }
          ) || nil,
          'gitlab-shell': (node.dig('gitaly', 'configuration', 'gitlab-shell') || {}).merge(
            {
              dir: '/opt/gitlab/embedded/service/gitlab-shell'
            }
          ),
        }
      ).compact
    }
  )
  notifies :hup, "runit_service[gitaly]" if omnibus_helper.should_notify?('gitaly')
  sensitive true
end

runit_service 'gitaly' do
  start_down node['gitaly']['ha']

  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    working_dir: working_dir,
    env_dir: env_directory,
    bin_path: gitaly_path,
    wrapper_path: wrapper_path,
    config_path: config_path,
    log_directory: logging_settings[:log_directory],
    log_user: logging_settings[:runit_owner],
    log_group: logging_settings[:runit_group],
    json_logging: json_logging,
    open_files_ulimit: open_files_ulimit,
    cgroups_mountpoint: cgroups_mountpoint,
    cgroups_hierarchy_root: cgroups_hierarchy_root,
    cgroups_enabled: cgroups_enabled,
    cgroups_v2_enabled: Gitaly.cgroups_v2?(cgroups_mountpoint),
    cgroups_parent_cgroup_procs_file: cgroups_parent_cgroup_procs_file,
    use_wrapper: use_wrapper,
  }.merge(params))
  log_options logging_settings[:options]
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start gitaly" do
    retries 20
  end
end

version_file 'Create version file for Gitaly' do
  version_file_path File.join(working_dir, 'VERSION')
  version_check_cmd "/opt/gitlab/embedded/bin/ruby -rdigest/sha2 -e 'puts %(sha256:) + Digest::SHA256.file(%(/opt/gitlab/embedded/bin/gitaly)).hexdigest'"
  notifies :hup, "runit_service[gitaly]"
end

consul_service node['gitaly']['consul_service_name'] do
  id 'gitaly'
  meta node['gitaly']['consul_service_meta']
  action Prometheus.service_discovery_action
  socket_address node.dig('gitaly', 'configuration', 'prometheus_listen_addr')
  reload_service false unless Services.enabled?('consul')
end
