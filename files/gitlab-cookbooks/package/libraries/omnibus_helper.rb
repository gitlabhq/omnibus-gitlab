require 'mixlib/shellout'
require_relative 'helper'
require_relative 'deprecations'

class OmnibusHelper
  include ShellOutHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def service_dir_enabled?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}")
  end

  def should_notify?(service_name)
    service_dir_enabled?(service_name) && service_up?(service_name) && service_enabled?(service_name)
  end

  def not_listening?(service_name)
    return true unless service_enabled?(service_name)

    service_down?(service_name)
  end

  def service_enabled?(service_name)
    # Dealing with sidekiq and sidekiq-cluster separatly, since `sidekiq-cluster`
    # could be configured through `sidekiq`
    # This be removed after https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/240
    # The sidekiq services are still in the old `node['gitlab']`
    return sidekiq_service_enabled? if service_name == 'sidekiq'
    return sidekiq_cluster_service_enabled? if service_name == 'sidekiq-cluster'

    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.
    return node['monitoring'][service_name]['enable'] if node['monitoring'].key?(service_name)
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

  def is_deprecated_praefect_config?
    return unless node['praefect']['storage_nodes'].is_a?(Array)

    msg = <<~EOS
      Specifying Praefect storage nodes as an array is deprecated. Support will be removed in a future release.
      Check the latest gitlab.rb.template for the current format.
      https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template
    EOS

    LoggingHelper.deprecation(msg)
  end

  def self.utf8_variable?(var)
    ENV[var]&.downcase&.include?('utf-8') || ENV[var]&.downcase&.include?('utf8')
  end

  def self.valid_variable?(var)
    !ENV[var].nil? && !ENV[var].empty?
  end

  def self.on_exit
    LoggingHelper.report
  end

  def self.deprecated_os_list
    # This hash follows the format `'ohai-slug' => 'EOL version'
    # example: deprecated_os = { 'raspbian-8' => 'GitLab 11.8' }
    {
      'raspbian-9' => 'GitLab 13.4',
      'debian-8' => 'GitLab 13.4'
    }
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
      Starting with #{deprecated_os[matching_list.first]}, packages will not be built for it.
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

  def self.check_environment
    ENV['LD_LIBRARY_PATH'] && LoggingHelper.warning('LD_LIBRARY_PATH was found in the env variables, this may cause issues with linking against the included libraries.')
  end

  def self.check_locale
    error_message = "Environment variable %{variable} specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings."
    relevant_vars = %w[LC_CTYPE LC_COLLATE]

    # LC_ALL variable trumps everything. If it specify a locale, we  can make
    # a decision based on that and need not check more.
    if valid_variable?('LC_ALL')
      LoggingHelper.warning(format(error_message, variable: 'LC_ALL')) unless utf8_variable?('LC_ALL')
      return
    end

    # We know LC_COLLATE and LC_CTYPE variables being non-UTF8 will definitely
    # break stuff. So we check for them.
    individually_set_vars = relevant_vars.select { |var| valid_variable?(var) }
    individually_set_vars.each do |var|
      LoggingHelper.warning(format(error_message, variable: var)) unless utf8_variable?(var)
    end

    # If both LC_COLLATE and LC_CTYPE are UTF-8, initdb won't break. However,
    # if one of them is set and the other is empty, we defer to LANG.
    return if individually_set_vars == relevant_vars

    # Instead of setting LC_COLLATE and LC_CTYPE individually, users may have
    # also just set LANG variable. Next, we check for that. For example where
    # LC_CTYPE is UTF-8, but LANG is not (and thus LC_COLLATE is not).
    # This scenario can break initdb.
    return unless valid_variable?('LANG')

    LoggingHelper.warning(format(error_message, variable: 'LANG')) unless utf8_variable?('LANG')
  end

  def sidekiq_cluster_service_name
    node['gitlab']['sidekiq']['cluster'] ? 'sidekiq' : 'sidekiq-cluster'
  end

  def restart_service_resource(service)
    return "sidekiq_service[#{service}]" if %w(sidekiq sidekiq-cluster).include?(service)
    return "unicorn_service[#{service}]" if %w(unicorn).include?(service)

    "runit_service[#{service}]"
  end

  private

  def sidekiq_service_enabled?
    node['gitlab']['sidekiq']['enable'] ||
      (node['gitlab']['sidekiq']['cluster'] && node['gitlab']['sidekiq-cluster']['enable'])
  end

  def sidekiq_cluster_service_enabled?
    node['gitlab']['sidekiq-cluster']['enable'] && !node['gitlab']['sidekiq']['cluster']
  end
end unless defined?(OmnibusHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
