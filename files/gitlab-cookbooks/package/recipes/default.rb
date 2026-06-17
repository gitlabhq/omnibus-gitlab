require_relative '../../package/libraries/settings_dsl.rb'
install_dir = node['package']['install-dir']
ENV['PATH'] = "#{install_dir}/bin:#{install_dir}/embedded/bin:#{ENV['PATH']}"

include_recipe 'package::config'

OmnibusHelper.check_deprecations
OmnibusHelper.check_environment
OmnibusHelper.check_locale

directory "/etc/gitlab" do
  owner "root"
  group "root"
  mode "0775"
  only_if { node['gitlab']['manage_storage_directories']['manage_etc'] }
end.run_action(:create)

node.default['gitlab']['bootstrap']['enable'] = false if File.exist?("/var/opt/gitlab/bootstrapped")

directory "Create /var/opt/gitlab" do
  path "/var/opt/gitlab"
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory "Create /var/log/gitlab" do
  path "/var/log/gitlab"
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory "#{install_dir}/embedded/etc" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

# Install our runit instance
include_recipe "package::runit"

# Make global sysctl commands available
include_recipe "package::sysctl"

# Create gitlab-www user.
# This recipe needs to run before gitlab-rails
# because we add `gitlab-www` user to some groups created by that recipe
include_recipe "package::web-server"

# We attempt to create and manage users/groups by default. If users wish to
# disable it, they can set `manage_accounts['enable']` to `false`, and
# `account` custom resource will not create them.
include_recipe "package::users"

OmnibusHelper.is_deprecated_os?

# Report on any deprecations we encountered at the end of the run
# There are three possible exits for a reconfigure run
# 1. Normal cinc-client run completion
# 2. cinc-client failed due to an exception
# 3. cinc-client failed for some other reason
# 1 and 3 are handled below. 2 is handled in our custom exception handler
# defined at files/gitlab-cookbooks/package/libraries/handlers/gitlab.rb
Chef.event_handler do
  on :run_completed do
    OmnibusHelper.on_exit
  end

  on :run_failed do
    OmnibusHelper.on_exit
  end
end
