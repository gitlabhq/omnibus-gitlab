class SELinuxDistroHelper
  REDHAT_RELEASE_FILE = '/etc/redhat-release'.freeze
  OS_RELEASE_FILE = '/etc/os-release'.freeze

  def self.selinux_supported?
    system_is_rhel7? || system_is_rhel8? || system_is_amazon_linux2? || system_is_amazon_linux2022?
  end

  def self.system_is_rhel7?
    platform_family == 'rhel' && platform_version&.start_with?('7.')
  end

  def self.system_is_rhel8?
    platform_family == 'rhel' && platform_version&.start_with?('8.')
  end

  def self.system_is_amazon_linux2?
    # Extra platform check to ensure we don't enable RHEL 2
    platform_family == 'rhel' && %w[amazon amzn].include?(platform&.downcase) && platform_version == '2'
  end

  def self.system_is_amazon_linux2022?
    # Extra platform check to ensure we don't enable RHEL 2
    platform_family == 'rhel' && %w[amazon amzn].include?(platform&.downcase) && platform_version == '2022'
  end

  def self.platform_family
    case platform
    when /oracle/, /centos/, /almalinux/, /rocky/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/, /amzn/
      'rhel'
    end
  end

  def self.platform
    contents = read_release_file(REDHAT_RELEASE_FILE)

    return get_redhatish_platform(contents) unless contents.nil?

    contents = read_release_file(OS_RELEASE_FILE)
    capture = contents&.match(/^ID="(?<id>\S+)"$/)
    capture&.values_at(:id)&.first
  end

  def self.platform_version
    contents = read_release_file(REDHAT_RELEASE_FILE)

    return get_redhatish_version(contents) unless contents.nil?

    contents = read_release_file(OS_RELEASE_FILE)
    capture = contents&.match(/^VERSION="(?<version>\d+)"$/)
    capture&.values_at(:version)&.first
  end

  def self.read_release_file(release_file = nil)
    File.exist?(release_file) ? File.read(release_file) : nil
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/v14.8.12/lib/ohai/plugins/linux/platform.rb#L23
  def self.get_redhatish_platform(contents)
    contents[/^Red Hat/i] ? 'redhat' : contents[/(\w+)/i, 1].downcase
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/v14.8.12/lib/ohai/plugins/linux/platform.rb#L34
  def self.get_redhatish_version(contents)
    contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/(release)? ([\d.]+)/, 2]
  end
end
