require 'mixlib/shellout'
require_relative 'helper'
require_relative 'deprecations'

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

  def self.on_exit
    LoggingHelper.report
  end

  def self.deprecated_os_list
    # This hash follows the format `'ohai-slug' => 'EOL version'
    # example: deprecated_os = { 'raspbian-8' => 'GitLab 11.8' }
    {}
  end

  def self.is_deprecated_os?
    deprecated_os = deprecated_os_list
    ohai ||= Ohai::System.new.tap do |oh|
      oh.all_plugins(['platform'])
    end.data

    platform = ohai['platform']
    platform = 'raspbian' if ohai['platform'] == 'debian' && /armv/.match?(ohai['kernel']['machine'])

    os_string = "#{platform}-#{ohai['platform_version']}"

    # Find list of deprecated OS that may match the system OS. Like debian-7.11 matching debian-7
    matching_list = deprecated_os.keys.select { |x| os_string =~ Regexp.new(x) }

    return if matching_list.empty?
    message = <<~EOS
      Your OS, #{os_string}, will be deprecated soon.
      Staring with #{deprecated_os[matching_list.first]}, packages will not be built for it.
    EOS

    LoggingHelper.deprecation(message)
  end

  def self.parse_current_version
    return unless File.exist?("/opt/gitlab/version-manifest.json")
    version_manifest = JSON.parse(File.read("/opt/gitlab/version-manifest.json"))
    version_components = version_manifest['build_version'].split(".")
    version_components[0, 2].join(".")
  end

  def self.check_deprecations
    current_version = parse_current_version
    return unless current_version

    # We need configuration from /etc/gitlab/gitlab.rb in a structure similar
    # to what will be stored in /opt/gitlab/nodes/{fqdn}.json. This means
    # config keys should have `gitlab` as their parent key (for example,
    # nginx['listen_address'] should become `gitlab['nginx']['listen_address']`
    # We are doing something similar in check_config command.
    gitlab_rb_config = Gitlab['node'].normal

    removal_messages = Gitlab::Deprecations.check_config(current_version, gitlab_rb_config, :removal)
    removal_messages.each do |msg|
      LoggingHelper.removal(msg)
    end
    raise "Removed configurations found in gitlab.rb. Aborting reconfigure." unless removal_messages.empty?

    deprecation_messages = Gitlab::Deprecations.check_config(current_version, gitlab_rb_config, :deprecation)
    deprecation_messages.each do |msg|
      LoggingHelper.deprecation(msg)
    end
  end
end unless defined?(OmnibusHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
