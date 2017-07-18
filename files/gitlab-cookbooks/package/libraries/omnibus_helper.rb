require 'mixlib/shellout'
require_relative 'helper'

class OmnibusHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(OmnibusHelper)` at the end of the class definition)
  include ShellOutHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def should_notify?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name) && service_enabled?(service_name)
  end

  def not_listening?(service_name)
    return true unless service_enabled?(service_name)

    service_down?(service_name)
  end

  def service_enabled?(service_name)
    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.
    return node['gitlab'][service_name]['enable'] if node['gitlab'].key?(service_name)
    node[service_name]['enable']
  end

  def service_up?(service_name)
    success?("/opt/gitlab/init/#{service_name} status")
  end

  def service_down?(service_name)
    failure?("/opt/gitlab/init/#{service_name} status")
  end

  def user_exists?(username)
    success?("id -u #{username}")
  end

  def group_exists?(group)
    success?("getent group #{group}")
  end
end unless defined?(OmnibusHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
