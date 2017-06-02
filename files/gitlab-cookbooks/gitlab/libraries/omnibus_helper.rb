require 'mixlib/shellout'
require_relative 'helper'

class OmnibusHelper
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
