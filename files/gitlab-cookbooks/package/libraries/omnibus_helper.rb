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

  def is_managed_and_offline?(service_name)
    service_enabled?(service_name) && service_down?(service_name)
  end

  def user_exists?(username)
    success?("id -u #{username}")
  end

  def group_exists?(group)
    success?("getent group #{group}")
  end

  def expected_user?(file, user)
    File.stat(file).uid == Etc.getpwnam(user).uid
  end

  def expected_group?(file, group)
    File.stat(file).gid == Etc.getgrnam(group).gid
  end

  def expected_owner?(file, user, group)
    expected_user?(file, user) && expected_group?(file, group)
  end

  def self.is_deprecated_os?
    deprecated_os = { 'debian-7' => 'GitLab 11.0' }
    ohai ||= Ohai::System.new.tap do |oh|
      oh.all_plugins(['platform'])
    end.data
    os_string = "#{ohai['platform']}-#{ohai['platform_version']}"

    # Find list of deprecated OS that may match the system OS. Like debian-7.11 matching debian-7
    matching_list = deprecated_os.keys.select { |x| os_string =~ Regexp.new(x) }

    return if matching_list.empty?
    message = <<~EOS
      Your OS, #{os_string}, will be deprecated soon.
      Staring with #{deprecated_os[matching_list.first]}, packages will not be built for it.
    EOS

    LoggingHelper.deprecation(message)
  end
end unless defined?(OmnibusHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
